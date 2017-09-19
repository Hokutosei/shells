# BUILD GKE Cluster for OEM
### ドキュメントの前提
 - mac ox
 - installed kubectl
 - GCP上のプロジェクトに 編集者(editor)権限
## 準備
### GCP上にプロジェクトを作成、APIの有効化、クラスタの作成
1. create project in GCP
2. enable API
    - API Manager -> ENABLE API -> Compute Engine API  
3. create container cluster
    - Menu > Container Engine > クラスタを作成 
    - node pool の作成
        - default-node[n1-standard-1]   x2　作成
        - pool-db0[n1-standard-1]  x2  作成（mongodb,mysql,redis用）
        - pool-db1[n1-standard-1]  x2  作成（elasticsearch用）
        - pool-lb[n1-standard-1]  x1  作成（nginx用）
    
4. Container Registry　をenableに
    - Menu > Container Registry > enableボタンをクリック 

### Login
省略


### Clusterの変更
 - $PROJECT = bizplatform-ix-production
 - $CLUSTER = ix-prod または ix-stg
 - $ZONE = asia-northeast1-a
```bash
gcloud config set project $PROJECT
gcloud config set container/cluster $CLUSTER
gcloud container clusters get-credentials $CLUSTER --zone $ZONE
```

### 確認
クラスタノードの確認
```bash
$ kubectl get nodes
```
```
NAME                                    STATUS    AGE
gke-ix-stg-default-pool-9015e997-5jbr   Ready     4h
gke-ix-stg-default-pool-9015e997-l1hf   Ready     4h
gke-ix-stg-pool-1-caa32221-w2br         Ready     19m
```

## MONGODBのビルド、デプロイ、設定

secure mongodb containerのビルド
```bash
$ cd path/to/deployments_root/mongodb/
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
デプロイメント（本番環境の場合は、prod-0.yml、prod-1.ymlを利用）
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

#### 管理ユーザの作成
admin dbの選択
```
> use admin
```
```
switched to db admin
```
#### レプリカ作成
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

管理者ユーザでログイン
```
rs0:PRIMARY> db.auth("devops","*******")
```
```
1
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

## MySQLのデプロイ、準備
#### デプロイ
```bash
$ cd ../mysql
$ kubectl create -f mysql/deployments/stg-0.yml
```
```
service "a-mysql-0" created
storageclass "a-mysql-0-pd-ssd" created
persistentvolumeclaim "a-mysql-0" created
deployment "a-mysql-0" created
```
Podの確認、コンテナへログイン
```bash
$ kubectl get pods
```
```
NAME                         READY     STATUS    RESTARTS   AGE
a-mongo-0-82809908-tv04h     1/1       Running   0          1h
a-mongo-1-1028953145-pf1rb   1/1       Running   0          50m
a-mysql-0-3056041181-ntl9g   1/1       Running   1          2m
```
```bash
$ kubectl exec -it a-mysql-0-3056041181-ntl9g /bin/bash
```
```bash
root@a-mysql-0:/# mysql -uroot -p
```
パスワードを入力
```bash
Enter password:
```
```
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 3
Server version: 5.7.17 MySQL Community Server (GPL)

Copyright (c) 2000, 2016, Oracle and/or its affiliates. All rights reserved.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>
```
データベースを作成 (use back-tick ` for db name )
```
mysql> create database `b-eee-dev`;
Query OK, 1 row affected (0.01 sec)
```
確認
```
mysql> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| b-eee-dev          |
| mysql              |
| performance_schema |
| sys                |
+--------------------+
5 rows in set (0.00 sec)
```

以上
```
mysql> quit
Bye
root@a-mysql-0:/# exit
exit
```


## Redisのビルド、デプロイ
#### コンテナのBuild、Push
```bash
$ cd ../redis
$ ./do.sh make
```
```
Sending build context to Docker daemon  48.64kB
Step 1/3 : FROM redis:3.2.3-alpine
 ---> 39fcd4ff9767
Step 2/3 : COPY redis.conf /usr/local/etc/redis/redis.conf
 ---> 35feb5cff5dd
Removing intermediate container 7f4bf75747d9
Step 3/3 : CMD redis-server /usr/local/etc/redis/redis.conf
 ---> Running in 10a82080e895
 ---> d71962b24859
Removing intermediate container 10a82080e895
Successfully built d71962b24859
The push refers to a repository [gcr.io/bizplatform-ix-production/redis]
e286afaaa8b6: Pushed
e563ba9af84a: Pushed
31d459b0aa2e: Pushed
faaa2b77199e: Pushed
e12005373f68: Pushed
072948560e04: Pushed
9007f5987db3: Pushed
3.2.3-alpine: digest: sha256:76f1df7f7e0e8171c0175da6b26dd4051473a340fe673bcc26c345c7a9cc535d size: 1777
```

#### Deploy
```bash
$ kubectl create -f deployments/stg-single.yml
```
```
service "a-redis" created
storageclass "redis-pd-ssd" created
persistentvolumeclaim "a-redis-data" created
deployment "a-redis" created
```
#### 確認
```bash
$ kubectl get pods
```
```
NAME                         READY     STATUS    RESTARTS   AGE
a-mongo-0-82809908-tv04h     1/1       Running   0          1h
a-mongo-1-1028953145-pf1rb   1/1       Running   0          1h
a-mysql-0-3056041181-ntl9g   1/1       Running   1          22m
a-redis-4099930026-k73r6     1/1       Running   0          1m
```
```bash
$ kubectl exec -it a-redis-4099930026-k73r6 redis-cli
```
```
127.0.0.1:6379> AUTH (password)
OK
```
(password) は、redis/redis.conf内の `requirepass` に指定されている

```
127.0.0.1:6379> KEYS *
(empty list or set)
```
以上
```
127.0.0.1:6379> exit
```

## elasticsearchのBuild,Deploy
コンテナのBuild ,Push
```bash
$ cd ../elasticsearch/docker
$ ./do.sh build
```
```
Sending build context to Docker daemon  15.87kB
Step 1/7 : FROM elasticsearch:5.2.1-alpine
 ---> 5a41a9c72cff
Step 2/7 : RUN bin/elasticsearch-plugin install analysis-kuromoji --batch
 ---> Running in 9e59711e549b
-> Downloading analysis-kuromoji from elastic
[=================================================] 100%
-> Installed analysis-kuromoji
 ---> 5681f24b26aa
Removing intermediate container 9e59711e549b
Step 3/7 : RUN bin/elasticsearch-plugin install ingest-attachment --batch
 ---> Running in c2b789bfe77a
-> Downloading ingest-attachment from elastic
[=================================================] 100%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@     WARNING: plugin requires additional permissions     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* java.lang.RuntimePermission getClassLoader
* java.lang.reflect.ReflectPermission suppressAccessChecks
* java.security.SecurityPermission createAccessControlContext
* java.security.SecurityPermission insertProvider
* java.security.SecurityPermission putProviderProperty.BC
See http://docs.oracle.com/javase/8/docs/technotes/guides/security/permissions.html
for descriptions of what these permissions allow and the associated risks.
-> Installed ingest-attachment
 ---> 0eeaa44f4efb
Removing intermediate container c2b789bfe77a
Step 4/7 : RUN bin/elasticsearch-plugin install org.codelibs:elasticsearch-analysis-kuromoji-neologd:5.2.1 --batch
 ---> Running in 54c8c6bd13bb
-> Downloading org.codelibs:elasticsearch-analysis-kuromoji-neologd:5.2.1 from maven central
[=================================================] 100%
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@     WARNING: plugin requires additional permissions     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
* java.lang.RuntimePermission accessDeclaredMembers
* java.lang.RuntimePermission getClassLoader
* java.lang.reflect.ReflectPermission suppressAccessChecks
See http://docs.oracle.com/javase/8/docs/technotes/guides/security/permissions.html
for descriptions of what these permissions allow and the associated risks.
-> Installed analysis-kuromoji-neologd
 ---> a5ae274f02cb
Removing intermediate container 54c8c6bd13bb
Step 5/7 : COPY userdict_ja.txt /usr/share/elasticsearch/config/userdict_ja.txt
 ---> b850b99947a0
Removing intermediate container 3560323518d5
Step 6/7 : COPY synonym.txt /usr/share/elasticsearch/config/synonym.txt
 ---> 2d38a3174c6f
Removing intermediate container 8c8c2ab3201d
Step 7/7 : COPY globalsearch_template.json /usr/share/elasticsearch/config/globalsearch_template.json
 ---> e21307f25d74
Removing intermediate container 2b98583aa00b
Successfully built e21307f25d74
The push refers to a repository [gcr.io/bizplatform-ix-production/elasticsearch5-ja]
62d54c33034e: Pushed
36bf059d8770: Pushed
3f858c6d1d74: Pushed
6b73034ccc4a: Pushed
c5b65cac9ffa: Pushed
a962b7dc34c3: Pushed
a7f82ae52d46: Pushed
ce5eb65afc5c: Pushed
bc5d99113bbd: Pushed
0227e2521da2: Pushed
b5179e9e72cd: Pushed
494d9dab3fce: Pushed
6f7515f19096: Pushed
da07d9b32b00: Pushed
7cbcbac42c44: Pushed
latest: digest: sha256:ce717c9c977bf502eaca2f11ce49725449cfbf021ef8f9776b4c5c7cc9bc6d65 size: 3455
```
上記、WARNING:は無視して問題ない

### Deploy
```
$ cd ..
$ kubectl create -f deployments/stg-0.yml
```
```
service "a-elasticsearch-0" created
storageclass "a-elasticsearch-0-pd-ssd" created
persistentvolumeclaim "a-elasticsearch-0" created
deployment "a-elasticsearch-0" created
```

## nsq のデプロイ
```
$ cd ../nsq
$ kubectl create -f deployments/stg-1.yml
```
```
service "a-nsq-1" created
deployment "a-nsq-1" created
```


## neo4j
```bash
$ cd ../neo4j
$ kubectl create -f deployments/stg.yml
```
```
service "d-neo4j-0" created
storageclass "d-neo4j-0-pd-ssd" created
persistentvolumeclaim "d-neo4j-0" created
deployment "d-neo4j-0" created
```
パスワードの設定(UIから設定)
```bash
$ kubectl port-forward d-neo4j-0-3932975958-nm4z8 7474:7474
```
- ブラウザからアクセス `http://localhost:7474/browser/`
- 左下Gearアイコンをクリックし、`Browser Settings` をひらく
- BOLT+ROUTING内の `Do not use Bolt`にチェックを入れる
- 初期ユーザ＆パスワード `neo4j`/`neo4j` でログイン
- 次の画面で初期パスワードを入力

以上

## 確認

サービスの確認
```bash
$ kubectl get services
```
```
NAME                CLUSTER-IP      EXTERNAL-IP      PORT(S)                                        AGE
a-elasticsearch-0   None            <none>           9200/TCP,9300/TCP                              3h
a-mongo-0           None            <none>           27017/TCP                                      5h
a-mongo-1           None            <none>           27017/TCP                                      5h
a-mysql-0           None            <none>           3306/TCP                                       4h
a-nsq-1             10.79.248.189   35.189.132.189   4150:32754/TCP,4151:32389/TCP,4171:31672/TCP   3h
a-redis             None            <none>           6379/TCP                                       4h
d-neo4j-0           None            <none>           80/TCP,7474/TCP                                7m
kubernetes          10.79.240.1     <none>           443/TCP                                        7h
```
Storage Class の確認
```bash
$ kubectl get storageclass
```
```
NAME                       KIND
a-elasticsearch-0-pd-ssd   StorageClass.v1.storage.k8s.io
a-mongo-0-pd-ssd           StorageClass.v1.storage.k8s.io
a-mongo-1-pd-ssd           StorageClass.v1.storage.k8s.io
a-mysql-0-pd-ssd           StorageClass.v1.storage.k8s.io
d-neo4j-0-pd-ssd           StorageClass.v1.storage.k8s.io
redis-pd-ssd               StorageClass.v1.storage.k8s.io
standard                   StorageClass.v1.storage.k8s.io
```

Persistent Volume Claim の確認
```bash
$ kubectl get pvc
```
```
NAME                    STATUS    VOLUME                                     CAPACITY   ACCESSMODES   AGE
a-elasticsearch-0       Bound     pvc-b4c9a506-1b84-11e7-a05a-42010a92000f   10Gi       RWO           3h
a-mongo-0               Bound     pvc-baa44341-1b6f-11e7-a05a-42010a92000f   50Gi       RWO           5h
a-mongo-1               Bound     pvc-60d3e454-1b72-11e7-a05a-42010a92000f   50Gi       RWO           5h
a-mysql-0               Bound     pvc-2a3325bb-1b79-11e7-a05a-42010a92000f   10Gi       RWO           4h
a-neo4j-0-a-neo4j-0-0   Bound     pvc-0b2b63a2-1b83-11e7-a05a-42010a92000f   10Gi       RWO           3h
a-redis-data            Bound     pvc-32116e28-1b7c-11e7-a05a-42010a92000f   10Gi       RWO           4h
d-neo4j-0               Bound     pvc-6ce2b056-1b9f-11e7-a05a-42010a92000f   10Gi       RWO           8m
```

Pod の確認
```bash
$ kubectl get pods
```
```
NAME                                 READY     STATUS    RESTARTS   AGE
a-elasticsearch-0-1786370560-xdn6n   1/1       Running   0          44m
a-mongo-0-82809908-h8rvj             1/1       Running   0          42m
a-mongo-1-1028953145-pf1rb           1/1       Running   0          5h
a-mysql-0-3056041181-0r4vm           1/1       Running   0          42m
a-nsq-1-3852233018-683s5             1/1       Running   1          3h
a-redis-4099930026-qf7fw             1/1       Running   0          41m
d-neo4j-0-3932975958-nm4z8           1/1       Running   0          9m
```


## マイクロサービスのデプロイ
以下の順番で実施（3以降は順不問）
1. configctl
2. apicore
3. notificator
4. importer
5. web-ui
6. b-eee-lp
7. mailfetcher
8. taskManager
9. linkerProxy

#### 前提
- gitからコードを checkout　出来る状態であること


### 該当マイクロサービスのディレクトリトップへ移動
```bash
$ cd $GOPATH/configctl
```
###  設定ファイルの準備
※運用手順書を参照
- GCP　 Storageの準備、バケット作成
- Sendgrid API Key準備
- Sentry　Key

### コンテナのビルドとPush、デプロイ

#### コンテナの作成、登録
stagingの場合
```bash
$ git pull origin develop
$ ./do.sh build_push bizplatform-ix-production
```
productionの場合
```bash
$ git pull origin master
./do.sh build_push bizplatform-ix-production
```
#### コンテナのデプロイ

デプロイフォルダへ移動
```bash
$ cd path/to/deployments_root/apps
```

デプロイ（delete は再作成のときのみ必要）
#### for staging
```bash
$ kubectl delete -f apps/[microservice-name]/depleyments/stg-deployments.yml 
$ kubectl create -f apps/[microservice-name]/depleyments/stg-deployments.yml 
```
#### for production
```bash
$ kubectl delete -f apps/[microservice-name]/depleyments/prod-deployments.yml 
$ kubectl create -f apps/[microservice-name]/depleyments/prod-deployments.yml 
```



## LB (Ingress) のデプロイ
### F/W Settings
1. GCPコンソールから、クラスタ選択
2. ノード内のインスタンスグループのリンクをクリック
   - インスタンス名の横にある「外部IP」がグローバルIPとなる
3. 該当VMインスタンスページへ
4. 編集→　インスタンス名(例えば、gke-ix-stg-pool-lb-3d554f6e-r20gのような名前)をコピーして、タグへ貼り付け、保存
5. GCPメニュー→ネットワーキングを選択
6. ネットワーク→defaultをクリック
7. 「ファイアウォールルールを追加」
   - 名前：default-https
   - ターゲットタグ：先程のインスタンス名を入力
   - ソースフィルタ：0.0.0.0/0
   - プロトコルとポート：　tcp:80;tcp:443

### Deploy ingress
※注意：　以下 production環境の場合は、stg部分をprodに変更して実行

デプロイフォルダへ移動
```bash
$ cd path/to/deployments_root/ingress
```

Certファイルをエンコード
```bash
$ base64 -i bizplatform-ix.com/bizplatform-ix.com.crt
$ base64 -i bizplatform-ix.com/bizplatform-ix.com.key
```

XXXX部分に、それぞれエンコードされた情報を貼り付けて、保存（→ deployments/cert/cert_bpix.yml）
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bpix-secret
type: Opaque
data:
  tls.crt: XXXX
  tls.key: XXXX
```

Cert情報をデプロイ
```bash
$ kubectl create -f deployments/cert/cert_bpix.yml
```
```
secret "bpix-secret" created
```

ConfigMapをデプロイ
```bash
$ kubectl create -f deployments/stg/configmaps/nginx-settings-configmap.yml
```
```
configmap "nginx-settings-configmap" created
```
```bash
$ kubectl create -f deployments/stg/configmaps/sticky-sessions.yml
```
```
configmap "nginx-ingress-sticky-session" created
```

NodePortをデプロイ
```
kubectl create -f deployments/stg/svc-nodeport.yml
```
```
service "nodeport-nginx" created
```

Ingressのデプロイ
```bash
$ kubectl create -f deployments/stg/ingress-stg.yml
```
```
ingress "bpix-stg" created
```

Nginx-Ingressのデプロイ
```bash
$ kubectl create -f deployments/stg/glbc-stg.yml
```
```
replicationcontroller "nginx-ingress-rc" created
```



以上


