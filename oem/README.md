# BUILD GKE Cluster for OEM
## ドキュメントの前提
 - mac ox
 - installed kubectl
 - GCP上のプロジェクトに 編集者(editor)権限
## 準備
### GCP上にプロジェクトを作成、APIの有効化、クラスタの作成
1. create project in GCP
2. enable API
    - API Manager -> ENABLE API -> Compute Engine API  
3. create container cluster
    - create cluster from webUI 
4. enable Container Registry
    - click from webUI 

### 確認
クラスタノードの確認
```bash
$ kubectl get nodes
```
```
NAME                                    STATUS    AGE
gke-ix-stg-default-pool-9015e997-5jbr   Ready     1h
gke-ix-stg-default-pool-9015e997-l1hf   Ready     1h
```

## 構築
### MONGODBのビルド、デプロイ、設定

secure mongodb containerのビルド
```bash
$ cd shells/oem/mongodb/
$ ./do.sh make
```
```
Sending build context to Docker daemon  11.78kB
Step 1/2 : FROM mongo:3.4.0
 ---> ca01b33b859a
Step 2/2 : COPY mongodb-keyfile /secret/
 ---> 861d2aa7a81f
Removing intermediate container 804aaa78f400
Successfully built 861d2aa7a81f
The push refers to a repository [gcr.io/bizplatform-ix-production/mongodb]
203cdcfd72e8: Pushed
62543ec60e00: Pushed
7671a01a405f: Pushed
71625f3196fd: Pushed
8039db5653d3: Pushed
f0735232b183: Pushed
45f4d47a35ee: Pushed
fadfb904b96a: Pushed
54dbf265f995: Pushed
b6ca02dfe5e6: Layer already exists
3.4.0: digest: sha256:8d18ef8a99fe405850e27a7795c4d86d73b5e3792deadce8ef16d730980a81fe size: 2406
```
デプロイメント
```bash
$ kubectl create -f deployments/stg-0.yml
```
```shell
service "a-mongo-0" created
storageclass "a-mongo-0-pd-ssd" created
persistentvolumeclaim "a-mongo-0" created
deployment "a-mongo-0" created
```
２台目の作成
```bash
$ kubectl create -f deployments/stg-1.yml
```
```
service "a-mongo-1" created
storageclass "a-mongo-1-pd-ssd" created
persistentvolumeclaim "a-mongo-1" created
deployment "a-mongo-1" created
```
mongodbの初期設定
```bash
$ kubectl exec -it a-mongo-0-82809908-tv04h mongo
```
```
MongoDB shell version v3.4.0
connecting to: mongodb://127.0.0.1:27017
MongoDB server version: 3.4.0
Welcome to the MongoDB shell.
For interactive help, type "help".
For more comprehensive documentation, see
	http://docs.mongodb.org/
Questions? Try the support group
	http://groups.google.com/group/mongodb-user
>
```

####管理ユーザの作成
admin dbの選択
```
> use admin
```
```
switched to db admin
```
ユーザの作成（パスワードは実際のものを入力する）
```
db.createUser({
    user: "devops",
    pwd: "********",
    roles: [ { role: "root", db: "admin" } ]
})
```
```
Successfully added user: {
	"user" : "devops",
	"roles" : [
		{
			"role" : "root",
			"db" : "admin"
		}
	]
}
```
####レプリカ作成
レプリカの初期化
```
> rs.initiate()
```
```
{
	"info2" : "no configuration specified. Using a default configuration for the set",
	"me" : "a-mongo-0:27017",
	"ok" : 1
}
```
確認
```
rs0:OTHER> rs.status()
```
```
{
	"set" : "rs0",
	"date" : ISODate("2017-04-07T09:27:07.885Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1491557223, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1491557223, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1491557223, 1),
			"t" : NumberLong(1)
		}
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "a-mongo-0:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 1947,
			"optime" : {
				"ts" : Timestamp(1491557223, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-04-07T09:27:03Z"),
			"electionTime" : Timestamp(1491556722, 2),
			"electionDate" : ISODate("2017-04-07T09:18:42Z"),
			"configVersion" : 1,
			"self" : true
		}
	],
	"ok" : 1
}
```
管理者ユーザでログイン
```
rs0:PRIMARY> db.auth("devops","*******")
```
```
1
```


レプリカの追加
```
rs0:PRIMARY> rs.add("a-mongo-1")
```
```
{ "ok" : 1 }
```

確認（mongo0がPRIMARY、mongo1がSECONDARY）
```
rs0:PRIMARY> rs.status()
```
```
{
	"set" : "rs0",
	"date" : ISODate("2017-04-07T09:38:47.658Z"),
	"myState" : 1,
	"term" : NumberLong(1),
	"heartbeatIntervalMillis" : NumberLong(2000),
	"optimes" : {
		"lastCommittedOpTime" : {
			"ts" : Timestamp(1491557923, 1),
			"t" : NumberLong(1)
		},
		"appliedOpTime" : {
			"ts" : Timestamp(1491557923, 1),
			"t" : NumberLong(1)
		},
		"durableOpTime" : {
			"ts" : Timestamp(1491557923, 1),
			"t" : NumberLong(1)
		}
	},
	"members" : [
		{
			"_id" : 0,
			"name" : "a-mongo-0:27017",
			"health" : 1,
			"state" : 1,
			"stateStr" : "PRIMARY",
			"uptime" : 2647,
			"optime" : {
				"ts" : Timestamp(1491557923, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-04-07T09:38:43Z"),
			"electionTime" : Timestamp(1491556722, 2),
			"electionDate" : ISODate("2017-04-07T09:18:42Z"),
			"configVersion" : 2,
			"self" : true
		},
		{
			"_id" : 1,
			"name" : "a-mongo-1:27017",
			"health" : 1,
			"state" : 2,
			"stateStr" : "SECONDARY",
			"uptime" : 61,
			"optime" : {
				"ts" : Timestamp(1491557923, 1),
				"t" : NumberLong(1)
			},
			"optimeDurable" : {
				"ts" : Timestamp(1491557923, 1),
				"t" : NumberLong(1)
			},
			"optimeDate" : ISODate("2017-04-07T09:38:43Z"),
			"optimeDurableDate" : ISODate("2017-04-07T09:38:43Z"),
			"lastHeartbeat" : ISODate("2017-04-07T09:38:46.267Z"),
			"lastHeartbeatRecv" : ISODate("2017-04-07T09:38:47.449Z"),
			"pingMs" : NumberLong(0),
			"syncingTo" : "a-mongo-0:27017",
			"configVersion" : 2
		}
	],
	"ok" : 1
}
```

以上
```
rs0:PRIMARY> exit
bye
```











## 確認

サービスの確認
```bash
kubectl get services
```
```
NAME         CLUSTER-IP    EXTERNAL-IP   PORT(S)     AGE
a-mongo-0    None          <none>        27017/TCP   20m
a-mongo-1    None          <none>        27017/TCP   1m
kubernetes   10.79.240.1   <none>        443/TCP     1h
```

Persistent Volume Claim の確認
```bash
kubectl get pvc
```
```
NAME        STATUS    VOLUME                                     CAPACITY   ACCESSMODES   AGE
a-mongo-0   Bound     pvc-baa44341-1b6f-11e7-a05a-42010a92000f   50Gi       RWO           20m
a-mongo-1   Bound     pvc-60d3e454-1b72-11e7-a05a-42010a92000f   50Gi       RWO           2m
```
Pod の確認
```bash
kubectl get pods
```
```
NAME                         READY     STATUS    RESTARTS   AGE
a-mongo-0-82809908-tv04h     1/1       Running   0          21m
a-mongo-1-1028953145-pf1rb   1/1       Running   0          2m
```




























