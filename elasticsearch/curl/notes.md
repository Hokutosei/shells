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
