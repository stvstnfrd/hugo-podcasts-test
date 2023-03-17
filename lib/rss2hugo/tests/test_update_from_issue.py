"""
Assert that we can update an index files from issue files
"""
import unittest
from unittest.mock import patch
from unittest.mock import Mock

import frontmatter

from rss2hugo.models import Feed

INDEX_GOOD = 'lib/rss2hugo/tests/fixtures/index-good.markdown'
ISSUE_GOOD = 'lib/rss2hugo/tests/fixtures/issue-good.markdown'


class TestUpdate(unittest.TestCase):
    """
    Ensure that we can update posts via issues
    """

    def test_update(self):
        """
        Ensure that updates do not break
        """
        index_file = 'index.markdown'
        issue_file = 'issue.markdown'
        index = frontmatter.load(INDEX_GOOD)
        issue = ''
        with open(ISSUE_GOOD, encoding='utf-8') as _file:
            issue = _file.readlines()
            issue = '\n'.join(issue)
        mocked_issue = Mock(return_value=[
            line + '\n'
            for line in issue.split('\n')
        ])
        mocked_index = Mock(return_value=index)
        with patch('frontmatter.load', mocked_index):
            with patch('rss2hugo.github.Issue._open', mocked_issue):
                Feed.update_from_issue(issue_file, index_file)
