# copy-appsdir.sh
## 要件
  2つの引数が必須。そして第1引数/appsディレクトリが存在する。  
## 動作
  第2引数/appsディレクトリを作成して、そこへ第1引数ディレクトリ/apps下のapk及びabファイルをハードリンクする。  
  第2引数ディレクトリに@listファイルを作成する(make-list.shを使う)。  
  第2引数ディレクトリに第1引数ディレクトリ下の@blacklistファイルをコピーする。  

# get-supplement.sh
## 要件
  単一の端末とadb接続ができる。  
  appsディレクトリにいる or カレント直下にappsディレクトリがある。  
  カレント直下に@listファイルがある。  
## 特徴
  ログとアプリリストはappsディレクトリの親ディレクトリ  に書かれる。  
## 動作
  端末のユーザーアプリを@origにリストする。  
  端末にあってappsディレクトリ下にも@blacklistファイルにもないアプリを@togetにリストする。  
  @togetのアプリ(のapk及びab)を端末から取得してapps下に置く。  
  @list,@orig,@togetをタイムスタンプ付きファイル名に変更して保存する。  
  新しい@listファイルを作る(make-list.shを使う)。  
  ログは log-get-デバイス名-タイムスタンプ に書かれる。  

# put-supplement.sh
## 要件
  単一の端末とadb接続ができる。  
  環境変数APPDIRが設定されている。  
  $APPDIR/appsディレクトリがある。  
  $APPDIR/@listファイルがある。  
## 特徴
  ログとアプリリストはカレントディレクトリに書かれる。  
## 動作
  端末のユーザーアプリを./@origにリストする。  
  $APPDIR/@listにあって端末にないアプリを./@toputにリストする。  
  @toputのアプリ(のapk及びab)を$APPDIR/appsから端末にインストールする。  
  @orig,@toputをタイムスタンプ付きファイル名に変更して保存する。  
  新しい@listファイルを作る(make-list.shを使う)。  
  ログは ./log-put-デバイス名-タイムスタンプ に書かれる。  

# add-black.sh
これから作る。ブラックリストにアプリ名"$@"のアプリを追加する。
→やっぱやめた。viによる編集とset-complementでできる。

# get-update.sh
これから作る。$APPDIR/appsのファイルを(最新だと想定される)端末のファイルで置き換える。

# make-list.sh
## 要件
  appsディレクトリにいる or カレント直下にappsディレクトリがある。  
## 動作
  apps下にapk又はabファイルのあるアプリのリストを、apps/../@listに作成。  

# make-withname.sh
## 要件
  appsディレクトリにいる or カレント直下にappsディレクトリがある。  
## 動作
  apps/../@listの各アプリに日本語のアプリ名称を付加したものを、  
  apps/../@list.withNameに作成。  

# TODO
- taimenのadb backupパスワード入力の先頭1文字が欠ける件へのグリッチ
- 作業が終わったor止まったときに端末のベルを鳴らす。
