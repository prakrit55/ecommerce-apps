const { NodeSDK } = require('@opentelemetry/sdk-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-grpc');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-grpc');
const { PeriodicExportingMetricReader } = require('@opentelemetry/sdk-metrics');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { Resource } = require('@opentelemetry/resources');

// Get the service name from environment variable, default to 'product-catalog'
const serviceName = process.env.OTEL_SERVICE_NAME || 'product-catalog';
const serviceVersion = process.env.OTEL_SERVICE_VERSION || '1.0.0';

// Setup OTLP endpoint, defaults to gRPC collector url
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4317';

console.log(`Initializing OpenTelemetry for service: ${serviceName} exporting to ${otlpEndpoint}`);

// Create trace exporter
const traceExporter = new OTLPTraceExporter({
  url: otlpEndpoint,
});

// Create metric exporter and reader
const metricExporter = new OTLPMetricExporter({
  url: otlpEndpoint,
});

const metricReader = new PeriodicExportingMetricReader({
  exporter: metricExporter,
  exportIntervalMillis: 60000, // Export metrics every 60 seconds
});

// Initialize the OpenTelemetry Node SDK
const sdk = new NodeSDK({
  resource: new Resource({
    'service.name': serviceName,
    'service.version': serviceVersion,
  }),
  traceExporter: traceExporter,
  metricReader: metricReader,
  instrumentations: [
    getNodeAutoInstrumentations({
      // We can customize configuration for specific instrumentations here if needed
      '@opentelemetry/instrumentation-fs': {
        enabled: false, // Disabling fs to keep trace noise down
      },
    }),
  ],
});

// Start the SDK
try {
  sdk.start();
  console.log('OpenTelemetry SDK started successfully');
} catch (error) {
  console.error('Error starting OpenTelemetry SDK:', error);
}

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('OpenTelemetry SDK terminated'))
    .catch((error) => console.error('Error terminating OpenTelemetry SDK', error))
    .finally(() => process.exit(0));
});
