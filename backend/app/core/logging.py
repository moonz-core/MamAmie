import logging
import re
import sys
from app.core.config import settings

SENSITIVE_PATTERNS = [
    (re.compile(r'("password"|"token"|"secret"|"authorization"):\s*"[^"]+"', re.IGNORECASE), r'\1: "[REDACTED]"'),
    (re.compile(r'(Bearer\s+)[A-Za-z0-9\-\._~\+\/]+=*', re.IGNORECASE), r'\1[REDACTED_TOKEN]'),
]


class SanitizedFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        msg = super().format(record)
        for pattern, replacement in SENSITIVE_PATTERNS:
            msg = pattern.sub(replacement, msg)
        return msg


def setup_logging():
    level = logging.DEBUG if settings.DEBUG else logging.INFO
    formatter = SanitizedFormatter(
        fmt="%(asctime)s | %(levelname)-7s | %(name)s:%(funcName)s:%(lineno)d - %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S"
    )

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(formatter)

    root_logger = logging.getLogger()
    root_logger.setLevel(level)
    root_logger.handlers = [handler]

    # Silence overly verbose third-party loggers
    logging.getLogger("aiosqlite").setLevel(logging.WARNING)
    logging.getLogger("asyncio").setLevel(logging.WARNING)


logger = logging.getLogger("mamamie")
