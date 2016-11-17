ductile
=======

Elasticsearch Bulk Loader for quick export/import of bulk formatted data.

## Install

```bash
$ npm install -g ductile
```

## Usage

### Export

```bash
$ ./ductile export --help

 Usage: ductile export [options] <url>

Options:
  --help           Show help  [boolean]
  -d, --delete     output delete operations  [boolean] [default: false]
  -q, --query      file with json query  [string]
  -t, --transform  file with transform function  [string]
```

### Import

```bash
$ ./ductile import --help

 Usage: ductile import [options] <url>

Options:
  --help           Show help  [boolean]
  -d, --delete     change incoming index operations to delete  [boolean] [default: false]
  -t, --transform  file with transform function  [string]
```

## Examples

This tools works with stdin/stdout.

### Export

```bash
$ ductile export http://elastichost:9200/myindex
{"index":{"_index":"myindex","_type":"mytype","_id":"sdltb459b78"}}
{"type":"picture","mimetype":"image/jpeg","representationtype":"complete","pubstatus":"usable","copyrightholder":"Afp","product":[{"code":"FOAFP","nam
...
```

#### To file

```bash
$ ductile export http://elastichost:9200/myindex > dump.bulk
```

#### With type

```bash
$ ductile export http://elastichost:9200/myindex/mytype > dump.bulk
```

#### To delete operations

```bash
$ ./ductile export -d http://devbox.local:9200/myindex
{"delete":{"_index":"myindex","_type":"mytype","_id":"sdltb459b78"}}
{"delete":{"_index":"myindex","_type":"mytype","_id":"sdltb45b7ad"}}
{"delete":{"_index":"myindex","_type":"mytype","_id":"sdltb45b7cc"}}
{"delete":{"_index":"myindex","_type":"mytype","_id":"sdltb45be86"}}
```

#### With a query

Queries are JSON formatted elasticsearch queries. The default query is a `match_all`.
The query file is `require`, so it can also be expressed as `.js` or `.coffee`

```bash
$ ./ductile export -q ./query.json http://devbox.local:9200/dist-sdl-20160314
{"index":{"_index":"myindex","_type":"mytype","_id":"sdltb459b78"}}
{"type":"picture","mimetype":"image/jpeg","representationtype":"complete","pubstatus":"usable","copyrightholder":"Afp","product":[{"code":"FOAFP","nam
```

The `query.json`:

```json
{
  "query": {
    "match_all": {}
  }
}
```

#### Transform output

Output can optionally be transformed before turned into bulk.
The transform file is `require`, and must produce a function.

```bash
$ ductile export -t ./mytransform.js http://elastichost:9200/myindex/mytype > dump.bulk
```

The `mytransform.js`:

```js
module.exports = function(hit) {
    hit._source.changedvalue = "PANDA!";
    return hit;
};
```

*The function must return the item.* Returning nothing or `null` will
drop the item, and can be used as a programmatic filter.

The input to the function is a hit as produced by elasticsearch.
Any part of the input can be changd.

```json
{
  "_index": "myindex",
  "_type": "mytype",
  "_id": "sdltb459b78",
  "_score": 1,
  "_source": {  }
}
```

## Import

### From an export

```bash
$ ductile export http://host1:9200/myindex1 | ductile import http://host2:9200/myindex2
```

### From a file

```bash
$ ductile import http://elastichost:9200/myindex < dump.bulk
```

### Make delete operations

Index operations can be turned to delete operations.

```bash
$ ductile import -d http://elastichost:9200/myindex < dump-with-index-oper.bulk
```

### Transform input

Input can be optionally transformed. 
The transform file is `require`, and must produce a function.

```bash
$ ductile import -t ./mytransform.js http://elastichost:9200/myindex/mytype < dump.bulk
```

The `mytransform.js`:

```js
module.exports = function(hit) {
    hit._source.changedvalue = "PANDA!";
    return hit;
};
```

*The function must return the item.* Returning nothing or `null` will
drop the item, and can be used as a programmatic filter.

Even though the input is a bulk format, the the input to the function 
is a synthetic hit similar to that produced by elasticsearch searches.
Any part of the input can be changd.

Worth noting is the non-elasticsearch-standard `_oper` field that
will hold one of `index`, `create`, `delete` or `update`.

```json
{
  "_index": "myindex",
  "_type": "mytype",
  "_id": "sdltb459b78",
  "_score": 1,
  "_oper": "index",
  "_source": {  }
}
```


## License

The MIT License (MIT)

Copyright © 2016 Martin Algesten

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
