"""
Test our logging capabilities

Since we're using TSVs (tab-separated-values) for our logging format,
our concern is that messages are properly escaped;
messages should never contain TABS or NEWLINES.
All other characters are acceptable.
"""
import unittest

from rss2hugo import log


TAB = '	'
TAB_ESCAPED = '\\t'
NEWLINE = """
"""
NEWLINE_ESCAPED = '\\n'
FIELDS = ('foo', 'bar')

TEXT_WITH_TABS = TAB.join(FIELDS)
TEXT_WITH_NEWLINES = NEWLINE.join(FIELDS)
TEXT_WITH_TABS_AND_NEWLINES = (TAB + NEWLINE).join([
    TEXT_WITH_TABS,
    TEXT_WITH_NEWLINES,
])


class TestLogging(unittest.TestCase):
    """
    Test that our logging generally works
    """

    def setUp(self):
        self.name = __name__
        self.level = 'INFO'

    def _log(self, message):
        """
        Log a message; it should never contain:
        - TABS
        - NEWLINES
        """
        with self.assertLogs(self.name, level=self.level) as output:
            logger = log.get_logger(self.name, self.level)
            logger.info(message)
        for record in output.records:
            message = record.msg
            self.assertNotIn(TAB, message)
            self.assertNotIn(NEWLINE, message)
        return output

    def test_tabs(self):
        """
        Ensure tabs are always escaped
        """
        output = self._log(TEXT_WITH_TABS)
        for record in output.records:
            message = record.msg
            self.assertIn(TAB_ESCAPED, message)

    def test_newlines(self):
        """
        Ensure newlines are always escaped
        """
        output = self._log(TEXT_WITH_NEWLINES)
        for record in output.records:
            message = record.msg
            self.assertIn(NEWLINE_ESCAPED, message)

    def test_tabs_and_newlines(self):
        """
        Ensure tabs and newlines are always escaped
        """
        output = self._log(TEXT_WITH_TABS_AND_NEWLINES)
        for record in output.records:
            message = record.msg
            self.assertIn(TAB_ESCAPED, message)
            self.assertIn(NEWLINE_ESCAPED, message)
            self.assertIn(NEWLINE_ESCAPED, message)
