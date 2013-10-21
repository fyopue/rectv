rectv
=====

PT3用TV録画スクリプト

著作権表示 / 免責事項 / その他諸注意

  作成：まほろば紳士ちゃん☆ゆうゆゆう（fyopue）
  Twitter： fyopue
  blog： http://www.kotokoi.org/
  github： https://github.com/fyopue/

  このスクリプトはbash上で動くスクリプトです。
  LinuxMint13上での動作確認を行なっています。
  ほかの環境ではコマンドのパス構造が違うなど正常に動作しない可能性があります。

  しょぼいカレンダーからデータを取得している関係でアニメ専用になっていますが、
  ほかのサイトからデータを取得すればアニメ以外にも使えます。
  MITライセンスで配布しますので好きなようにカスタマイズしてください。

  録画用HDD2台までの構成を前提にしています。
  あくまで個人利用のために書いたスクリプトですので機能的に不足している部分は、
  各自適切な修正、追加を行なって利用してください。

  このスクリプトを使用してPCに不具合等発生してもまほろば紳士は責任をとることはできません。
  自身で責任をとれる範囲で使用してください。
  使用に際してわずかでも不安を感じるようであれば使用しないでください。

  スクリプトに関する質問は面倒でないものに関しては可能な限りお答えします。
  面倒なものは無視します。英語は苦手です。

  使い方はスクリプトとreadmeを隅から隅まで読みこんで無理なら諦めてください。
  LinuxでPT3サーバが構築できる程度の技術があれば問題なく使用できます。


■インストール

・Cronjob生成スクリプト（recdgen.sh）
  recdgen.sh（スクリプト本体）
  ch.list（チャンネル変換表）
  iepg.list（iepgダウンロードリスト）
  routine.list（その他Cronjobリスト）
  以上の4つのファイルを任意のディレクトリに保存します。
  recdgen.sh を開き 2行目 settingfile=/filedir/ の /filedir/ を*.listファイルを保存したディレクトリに書き換えます。
  同様に3行目 reclist=/filedir/ 4行目 reciepg=/filedir/ を任意のディレクトリに書き換えれば設定完了です。
  末尾には/をつけてください。

  パッケージに含まれている ch.list  iepg.list  routine.list はサンプルファイルです。
  内容はサンプルを参考に各個人の環境に合わせて作成してください。

  settingfileはユーザールート以下のディレクトリ、reclis、treciepgは/tmp/などにしておくと便利です。
  スクリプトには実行権限を忘れずに。

※注意：
  このスクリプトを実行すると、既存のcronjobをすべて上書きします。
  既存のjobがある場合は事前にroutine.listに移してください。
  $ crontab -l > ~/routine.list などとすると作業が簡単です。
  また、万一のためにcrontabの定期的なバックアップを必ず行なってください。


・録画スクリプト（rectv.sh）
  rectv.sh を任意のディレクトリに保存します。
  rectv.sh を開き 6行目 settingfile=/filedir/ の /filedir/ を
  recdgen.sh で書き換えたものと同じディレクトリに書き換えます。
  15行目 d1="hdd-id01" のhdd-id01を録画用HDD1台目のマウントポイントに、
  16行目 d2="hdd-id02" のhdd-id02を録画用HDD2台目のマウントポイントにそれぞれ書き換えれば設定完了です。


■使い方

・Cronjob生成スクリプト
  $ /home/usrdir/recdgen.sh

  Cronjob生成スクリプトはiepg.listに記載された番号のiepgファイルを取得して
  Cronjobを生成、routine.listの内容と結合してcrontabに登録します。
  元データはしょぼいカレンダーから取得しています。
  オプション、引数は特にありません。

  次のような書式のデータを生成します。
  0 0 * * 0 /home/usrdir/recode2.sh 20 29 "物語シリーズ_セカンドシーズン" 275088
  26 22 * * 0 /home/usrdir/rectv.sh 20 5 "てーきゅう(3)" 273803
  30 7 * * 2 /home/usrdir/rectv.sh 23 29 "マイリトルポニー" 274718

※注意：
  実行すると、既存のjobをすべて上書きします。
  既存のjobがある場合は事前にroutine.listに移してください。
  $ crontab -l > ~/routine.list などとすると作業が簡単です。
  また、万一のためにcrontabの定期的なバックアップを必ず行なってください。

・録画スクリプト
  $ /home/usrdir/rectv.sh [チャンネル番号] [時間（分）] ["タイトル"] [iepg番号]
  使用サンプル :
  $ /home/usrdir/rectv.sh 20 29 "物語シリーズ_セカンドシーズン" 275088

  録画スクリプトは[チャンネル番号][時間（分）]["タイトル"]を引数として読み込み指定の時間分録画を行います。
  オプションの引数として[iepg番号]を指定することができます。
  これは、Cronjob生成スクリプトで使用するiepg.listを更新するための数値です。



TV Program Generator for PT3 (recdgen.sh)
TV Recorder for PT3 (rectv.sh)

Command line

TV Program Generator for PT3
  $ /home/usrdir/recdgen.sh

TV Recorder for PT3
  $ /home/usrdir/rectv.sh [ch] [length(minute)] ["title"] [iepg]

  Sample : /home/usrdir/rectv.sh 20 29 "title" 275088
