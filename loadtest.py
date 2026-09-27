"""
E-Commerce Microservices Concurrent Load Testing Suite (Zero-Dependency)
========================================================================
Exercises all 6 microservices and databases through the Gateway / UI:
- Product Catalog (Node.js / MongoDB / Redis)
- Product Inventory (Python / Flask)
- Order Management & Cart (Java Spring Boot / PostgreSQL)
- Shipping & Handling (Go)
- Contact Support (Python / Flask)
- Ecommerce UI & API Gateway (Node.js)

Usage:
  python loadtest.py --host http://app.prakriti.website --concurrency 25 --duration 60
"""

import argparse
import random
import time
import sys
import urllib.request
import urllib.error
import json
import statistics
import threading
from collections import defaultdict
from concurrent.futures import ThreadPoolExecutor

if sys.stdout.encoding != 'utf-8':
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

ENDPOINTS = [
    # (Method, Path, Payload Gen, Weight)
    ("GET", "/api/products", None, 35),
    ("GET", "/api/products/{id}", lambda: {"id": random.randint(1, 12)}, 20),
    ("GET", "/api/inventory", None, 15),
    ("GET", "/api/inventory/{id}", lambda: {"id": random.randint(1, 12)}, 10),
    ("GET", "/api/orders/1/cart", None, 10),
    ("POST", "/api/orders/1/cart", lambda: {"id": random.randint(1, 12), "quantity": random.randint(1, 3)}, 8),
    ("GET", "/api/orders/1/cart/subtotal", None, 5),
    ("GET", "/api/orders/1/cart/shipping", None, 5),
    ("GET", "/api/all-shipping-fees", None, 5),
    ("GET", "/api/shipping-explanation", None, 3),
    ("GET", "/api/contact-message", None, 2),
    ("POST", "/api/contact-submit", lambda: {"name": "LoadTester", "email": "test@prakriti.website", "subject": "Benchmark", "message": "Automated performance load test"}, 2),
]

class ThreadSafeStats:
    def __init__(self):
        self.lock = threading.Lock()
        self.total_requests = 0
        self.successful_requests = 0
        self.failed_requests = 0
        self.status_codes = defaultdict(int)
        self.latencies = []
        self.endpoint_stats = defaultdict(lambda: {"total": 0, "success": 0, "fail": 0, "latencies": []})
        self.start_time = time.time()

    def record(self, method, endpoint, status_code, duration_ms, is_success):
        with self.lock:
            self.total_requests += 1
            self.status_codes[status_code] += 1
            self.latencies.append(duration_ms)
            
            ep_stat = self.endpoint_stats[f"{method} {endpoint}"]
            ep_stat["total"] += 1
            ep_stat["latencies"].append(duration_ms)

            if is_success:
                self.successful_requests += 1
                ep_stat["success"] += 1
            else:
                self.failed_requests += 1
                ep_stat["fail"] += 1

    def print_summary(self):
        elapsed = time.time() - self.start_time
        rps = self.total_requests / elapsed if elapsed > 0 else 0
        
        print("\n" + "=" * 78)
        print("  🎯 E-COMMERCE PLATFORM LOAD TEST SUMMARY")
        print("=" * 78)
        print(f"Total Duration:          {elapsed:.2f}s")
        print(f"Total Requests Sent:     {self.total_requests}")
        print(f"Throughput (RPS):        {rps:.2f} req/sec")
        print(f"Successful Requests:     {self.successful_requests} ({self.successful_requests/max(1, self.total_requests)*100:.1f}%)")
        print(f"Failed Requests:         {self.failed_requests} ({self.failed_requests/max(1, self.total_requests)*100:.1f}%)")
        print("\n--- HTTP Status Codes ---")
        for code, count in sorted(self.status_codes.items()):
            print(f"  HTTP {code}: {count} ({count/max(1, self.total_requests)*100:.1f}%)")

        if self.latencies:
            p50 = statistics.median(self.latencies)
            sorted_lat = sorted(self.latencies)
            p90 = sorted_lat[int(len(sorted_lat) * 0.90)]
            p95 = sorted_lat[int(len(sorted_lat) * 0.95)]
            p99 = sorted_lat[min(int(len(sorted_lat) * 0.99), len(sorted_lat) - 1)]
            avg_lat = statistics.mean(self.latencies)
            print("\n--- Platform Latency & Response Times (ms) ---")
            print(f"  Average:  {avg_lat:.2f} ms")
            print(f"  Median:   {p50:.2f} ms")
            print(f"  P90:      {p90:.2f} ms")
            print(f"  P95:      {p95:.2f} ms (SLO Target: ≤250ms -> {'✅ PASS' if p95 <= 250 else '⚠️ WARN'})")
            print(f"  P99:      {p99:.2f} ms")
            print(f"  Min/Max:  {min(self.latencies):.2f} ms / {max(self.latencies):.2f} ms")

        print("\n--- Microservice Endpoint Breakdown ---")
        print(f"{'Endpoint':<42} {'Reqs':<8} {'Success':<8} {'Avg(ms)':<10} {'P95(ms)':<10}")
        print("-" * 78)
        for ep, data in sorted(self.endpoint_stats.items()):
            ep_lats = sorted(data["latencies"])
            ep_avg = statistics.mean(ep_lats) if ep_lats else 0
            ep_p95 = ep_lats[int(len(ep_lats) * 0.95)] if ep_lats else 0
            print(f"{ep:<42} {data['total']:<8} {data['success']:<8} {ep_avg:<10.1f} {ep_p95:<10.1f}")
        print("=" * 78 + "\n")


def pick_weighted_endpoint():
    endpoints, weights = [], []
    for method, path, payload_gen, weight in ENDPOINTS:
        endpoints.append((method, path, payload_gen))
        weights.append(weight)
    return random.choices(endpoints, weights=weights, k=1)[0]


def worker_thread(host, end_time, stats, min_delay, max_delay):
    while time.time() < end_time:
        method, raw_path, payload_gen = pick_weighted_endpoint()
        payload = payload_gen() if payload_gen else None
        
        if "{id}" in raw_path:
            item_id = payload.pop("id") if (payload and "id" in payload) else random.randint(1, 12)
            path = raw_path.replace("{id}", str(item_id))
        else:
            path = raw_path

        url = f"{host.rstrip('/')}{path}"
        headers = {
            "Content-Type": "application/json",
            "User-Agent": "Ecom-LoadTester/1.0"
        }
        
        start = time.perf_counter()
        status_code = 0
        is_success = False

        try:
            req_data = json.dumps(payload).encode("utf-8") if payload else None
            req = urllib.request.Request(url, data=req_data, headers=headers, method=method)
            with urllib.request.urlopen(req, timeout=10) as response:
                response.read()
                status_code = response.status
                is_success = (status_code < 400)
        except urllib.error.HTTPError as e:
            status_code = e.code
            is_success = (status_code < 400)
        except Exception:
            status_code = 0
            is_success = False
        finally:
            duration_ms = (time.perf_counter() - start) * 1000
            stats.record(method, raw_path, status_code, duration_ms, is_success)

        if max_delay > 0:
            time.sleep(random.uniform(min_delay, max_delay))


def main():
    parser = argparse.ArgumentParser(description="E-Commerce Microservices Load Generator")
    parser.add_argument("--host", default="http://app.prakriti.website", help="Base URL (default: http://app.prakriti.website)")
    parser.add_argument("--concurrency", type=int, default=20, help="Number of concurrent worker threads (default: 20)")
    parser.add_argument("--duration", type=int, default=60, help="Duration in seconds (default: 60)")
    parser.add_argument("--min-delay", type=float, default=0.01, help="Min sleep between requests (sec)")
    parser.add_argument("--max-delay", type=float, default=0.05, help="Max sleep between requests (sec)")
    args = parser.parse_args()

    print(f"\n🚀 Launching Load Test against: {args.host}")
    print(f"👥 Concurrent Workers:       {args.concurrency}")
    print(f"⏱️  Duration:                 {args.duration} seconds")
    print(f"📊 Live Grafana Dashboard:   http://grafana.prakriti.website\n")
    print("Executing load test... Watch Grafana for real-time Golden Signals!")

    stats = ThreadSafeStats()
    end_time = time.time() + args.duration

    with ThreadPoolExecutor(max_workers=args.concurrency) as executor:
        futures = [
            executor.submit(worker_thread, args.host, end_time, stats, args.min_delay, args.max_delay)
            for _ in range(args.concurrency)
        ]
        for f in futures:
            f.result()

    stats.print_summary()


if __name__ == "__main__":
    main()
