import frontmatter


class Issue(frontmatter.Post):

    def update(self, filename):
        data = self.data
        index = frontmatter.load(filename)
        index = index.to_dict()
        merged = {
            **index,
            **data
        }
        description = merged['description']
        del merged['description']
        del merged['content']
        post = frontmatter.Post(description, **merged)
        contents = frontmatter.dumps(post)
        with open(filename, 'w', encoding='utf-8') as _file:
            _file.write(contents)

    @classmethod
    def from_file(cls, filename):
        with open(filename) as _file:
            contents = _file.readlines()
        inside = None
        data = {}
        text = []
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

