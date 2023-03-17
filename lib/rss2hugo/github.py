"""
Handle GitHub-related tasks
"""
import frontmatter


class Issue(frontmatter.Post):
    """
    Treat GitHub Issues as normal Markdown posts
    """

    @classmethod
    def _open(cls, filename):  # pragma: no cover
        with open(filename, encoding='utf-8') as _file:
            contents = _file.readlines()
        return contents

    @classmethod
    def from_file(cls, filename):
        """
        Create a new Issue based on file contents
        """
        inside = None
        data = {}
        text = []
        contents = cls._open(filename)
        for line in contents:
            text.append(line)
            if line.startswith('### '):
                line = line[4:-1]
                line = line.lower()
                if inside:
                    data[inside] = '\n'.join(data[inside][1:-1])
                inside = line
                data[inside] = []
            elif inside:
                line = line[:-1]
                data[inside].append(line)
        data[inside] = '\n'.join(data[inside][1:])
        text = ''.join(text)
        issue = cls(text, **data)
        return issue
