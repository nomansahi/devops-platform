import io
import json
import tempfile
import unittest
from contextlib import redirect_stdout
from pathlib import Path

import app as application
from prometheus_client import REGISTRY


class ApplicationTests(unittest.TestCase):
    def setUp(self):
        self.temp_directory = tempfile.TemporaryDirectory()
        self.original_database = application.DATABASE
        application.DATABASE = str(
            Path(self.temp_directory.name) / "test.db"
        )
        self.client = application.app.test_client()

    def tearDown(self):
        application.DATABASE = self.original_database
        self.temp_directory.cleanup()

    def test_health_and_metrics(self):
        response = self.client.get("/health")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.get_json(), {"status": "healthy"})
        self.assertIn("X-Request-ID", response.headers)

        metrics = self.client.get("/metrics")

        self.assertEqual(metrics.status_code, 200)
        self.assertIn(
            "app_db_connection_success 1.0",
            metrics.get_data(as_text=True),
        )

    def test_http_failure_has_correlated_error_log(self):
        captured = io.StringIO()

        with redirect_stdout(captured):
            response = self.client.get("/fail")

        log = json.loads(captured.getvalue().strip())

        self.assertEqual(response.status_code, 500)
        self.assertEqual(log["level"], "ERROR")
        self.assertEqual(log["error_code"], "SIMULATED_FAILURE")
        self.assertEqual(log["route"], "/fail")
        self.assertEqual(
            log["request_id"],
            response.headers["X-Request-ID"],
        )

    def test_sql_error_does_not_mean_connection_failure(self):
        errors_before = REGISTRY.get_sample_value(
            "app_db_queries_total",
            {"result": "error"},
        )

        captured = io.StringIO()

        with redirect_stdout(captured):
            successful = self.client.get("/db")
            failed = self.client.get("/db-fail")

        self.assertEqual(successful.status_code, 200)
        self.assertEqual(successful.get_json(), {"result": 1})
        self.assertEqual(failed.status_code, 500)

        logs = [
            json.loads(line)
            for line in captured.getvalue().splitlines()
        ]
        self.assertEqual(
            logs[-1]["error_code"],
            "DATABASE_QUERY_FAILED",
        )

        errors_after = REGISTRY.get_sample_value(
            "app_db_queries_total",
            {"result": "error"},
        )
        self.assertEqual(errors_after - errors_before, 1)

        metrics = self.client.get("/metrics")
        self.assertIn(
            "app_db_connection_success 1.0",
            metrics.get_data(as_text=True),
        )


if __name__ == "__main__":
    unittest.main()