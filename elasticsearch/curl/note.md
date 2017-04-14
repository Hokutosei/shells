## notes for es settings using curl


create index using template
```
curl -XPUT -uelastic http://(HOST_IP):9200/_template/global_template\?pretty -d @test_template.json
```

check mappings
```
curl -XGET -uelastic http://(HOST_IP):9200/global_search/_mappings\?pretty
```

delete index
```
curl -XDELETE -uelastic http://(HOST_IP):9200/global_search
```


---

check indexed data
```
curl -XGET -uelastic http://104.198.89.246:9200/global_search/file_search/58cd077efbfcba2d6c055330
```

