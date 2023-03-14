import sys

import frontmatter


def parse_data_from_issue_file(filename):
    with open(filename) as _file:
        contents = _file.readlines()
    inside = None
    data = {}
    for line in contents:
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
    data = clean_data(data)
    return data


def clean_data(data):
    tags = list(data['category'].split(', ') + data['categories'].split(', '))
    del data['category']
    del data['categories']
    del data['action']
    data['tags'] = tags
    data['explicit'] = data['explicit'].lower() not in ['clean', 'no', 'false']

    feed = {}
    for key in data:
        if key in ['explicit', 'type']:
            feed[key] = data[key]
    for key in feed:
        del data[key]
    data['feed'] = feed
    return data


def merge_to_index(data, filename):
    index = frontmatter.load(filename)
    index = index.to_dict()
    merged = {
        **index,
        **data
    }
    description = merged['description']
    del merged['description']
    del merged['content']
    print('wtf', merged)
    post = frontmatter.Post(description, **merged)
    contents = frontmatter.dumps(post)
    with open(filename, 'w', encoding='utf-8') as _file:
        _file.write(contents)


def main():
    index_file = sys.argv[1]
    issue_file = sys.argv[2]
    data = parse_data_from_issue_file(issue_file)
    merge_to_index(data, index_file)


if __name__ == '__main__':
    main()
