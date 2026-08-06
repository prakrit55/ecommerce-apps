import { NodeSDK } from '@opentelemetry/sdk-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-grpc';
import { OTLPMetricExporter } from '@opentelemetry/exporter-metrics-otlp-grpc';
import { PeriodicExportingMetricReader } from '@opentelemetry/sdk-metrics';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import pkg from '@opentelemetry/resources';
const { resourceFromAttributes } = pkg;

const serviceName = process.env.OTEL_SERVICE_NAME || 'ecommerce-ui-server';
const serviceVersion = process.env.OTEL_SERVICE_VERSION || '1.0.0';
const otlpEndpoint = process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4317';

console.log(`Initializing OpenTelemetry for service: ${serviceName} exporting to ${otlpEndpoint}`);

const traceExporter = new OTLPTraceExporter({ url: otlpEndpoint });
const metricExporter = new OTLPMetricExporter({ url: otlpEndpoint });
const metricReader = new PeriodicExportingMetricReader({
  exporter: metricExporter,
  exportIntervalMillis: 60000,
});

const sdk = new NodeSDK({
  resource: resourceFromAttributes({
    'service.name': serviceName,
    'service.version': serviceVersion,
  }),
  traceExporter: traceExporter,
  metricReader: metricReader,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': {
        enabled: false,
      },
    }),
  ],
});

try {
  sdk.start();
  console.log('OpenTelemetry SDK started successfully');
} catch (error) {
  console.error('Error starting OpenTelemetry SDK:', error);
}

process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('OpenTelemetry SDK terminated'))
    .catch((error) => console.error('Error terminating OpenTelemetry SDK', error))
    .finally(() => process.exit(0));
});
