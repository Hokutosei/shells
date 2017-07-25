# SSL 証明書のアップデート手順
LINKER(GKE上に) のSSL証明書更新の手順をメモ

## 証明書の発行
このメモは、Cybertrust社の証明書を前提とする
###　CSRの作成

Private keyの作成
1.  暗号方式「des3」、公開鍵長「2048 bit」の秘密鍵ファイル「server.key」を作成
```bash
openssl genrsa -des3 -out server.key 2048
```
2. 秘密鍵ファイルのパスフレーズを入力


3. CSRを作成
```
openssl req -new -key server.key –out server.csr
```
3. 秘密鍵ファイルを作成した際のパスフレーズを入力
3. DN情報を入力
```
① Country Name（2 letter code）
    -> JP
    
② State or Province Name（full name）
    入力必須項目です。
    申請組織の都道府県を入力します。
    -> Tokyo
    
③ Locality Name（eg, city）
    入力必須項目です。
    申請組織の市町村を入力します。
    （東京は23区）
    -> Chiyoda-ku
    
④ Organization Name（eg, company）
    入力必須項目です。申請組織の英訳名を入力します。
    -> B-eee Technology,Inc.
    
⑤ Organization Unit Name（eg, section）
    任意入力項目です。
    申請組織の部署名などを入力します
    -> DevOps Division
    
⑥ Common Name（eg, your name oryour server’s hostname）
    入力必須項目です。
    申請するFQDNを入力します。
    例）www.b-eee.com
    
⑦ 以下の項目は入力不要のため、何も入力せずにエンターキーを押して進んでください。
    A) Email Address
    B) A challenge password
    C) An optional company name
```

以上で、`server.key` と `server.csr` ファイルが作成される

### 証明書発行
ログイン
https://certreq.digicert.ne.jp/DC/login/

```
ID : beeetech
PASS : OssuBeee14
```

- CSRをアップロード、その他必要事項の入力
- 審査後、メールで連絡あり。その後このサイトからcertファイルをダウンロード

`server.cer`　


## Deploy to GKE

### パスワードなしKeyファイルを準備

```bash
sudo openssl rsa -in server.key -out server_nopass.key
```
Enter pass phrase for server.key

`server_nopass.key`ができる

### Prepare secrets 

#### Certファイルをエンコード
```bash
$ base64 -i path/to/server.cer
$ base64 -i path/to/server.key
```

XXXX部分に、それぞれエンコードされた情報を貼り付けて、保存（→ cert.yml）
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: linker-secret
type: Opaque
data:
  tls.crt: XXXX
  tls.key: XXXX
```

#### Update Cert
```bash
$ kubectl apply -f path/to/cert.yml
secret "linker-secret" configured
```

### Ingressを再起動
```
kubectl delete pod <ingress pod>
```

