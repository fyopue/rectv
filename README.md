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
  ほかのサイトからデータを取得すればアニメ以外にも使えます（ファイルが連番になっている場合のみ）。  
  MITライセンスで配布しますので好きなようにカスタマイズしてください。

  録画用HDD2台までの構成を前提にしています。  
  あくまで個人利用のために書いたスクリプトですので機能的に不足している部分は、  
  各自適切な修正、追加を行なって利用してください。

  このスクリプトを使用してPCに不具合等発生してもまほろば紳士は責任を負いません。  
  自身で責任をとれる範囲で使用してください。  
  使用に際してわずかでも不安を感じるようであれば使用しないでください。

  スクリプトに関する質問は面倒でないものに関しては可能な限りお答えします。  
  面倒なものは無視します。英語は苦手です。

  使い方はスクリプトとreadmeを隅から隅まで読みこんで無理なら諦めてください。  
  LinuxでPT3サーバが構築できる程度の技術があれば問題なく使用できます。


■インストール

・Cronjob生成スクリプト（recdgen.sh）  
  recdgen.sh（スクリプト本体）  
  recstg/ch.list（チャンネル変換表）  
  recstg/iepg.list（iepgダウンロードリスト）  
  recstg/routine.list（その他Cronjobリスト）  
  以上の4つのファイルをホームディレクトリ以下の任意のディレクトリに保存します。   

  パッケージに含まれている ch.list  iepg.list  routine.list はサンプルファイルです。  
  内容はサンプルを参考に各個人の環境に合わせて作成してください。

  reclistは物理メモリ上に置いたディレクトリにしておくと便利です。  
  スクリプトには実行権限を忘れずに。

※注意：  
  このスクリプトを実行すると、既存のcronjobをすべて上書きします。  
  既存のjobがある場合は事前にroutine.listに移してください。  
  $ crontab -l > ~/routine.list などとすると作業が簡単です。  
  また、万一のためにcrontabの定期的なバックアップを必ず行なってください。  

・録画スクリプト（rectv.sh）  
  rectv.sh を任意のディレクトリに保存します。  
  9行目 d1="hdd-id01" のhdd-id01を録画用HDD1台目のマウントポイントに、  
  10行目 d2="hdd-id02" のhdd-id02を録画用HDD2台目のマウントポイントにそれぞれ書き換えれば設定完了です。  


■使い方

・Cronjob生成スクリプト  
  $ /home/usrdir/rectv/recdgen.sh

  Cronjob生成スクリプトはiepg.listに記載された番号のiepgファイルを取得して  
  Cronjobを生成、routine.listの内容と結合してcrontabに登録します。  
  元データはしょぼいカレンダーから取得しています。  
  オプション、引数はありません。

  次のような書式のデータを生成します。  
  0 0 * * 0 /home/usrdir/rectv/rectv.sh 20 29 "物語シリーズ_セカンドシーズン"  
  26 22 * * 0 /home/usrdir/rectv/rectv.sh 20 5 "てーきゅう(3)"  
  30 7 * * 2 /home/usrdir/rectv/rectv.sh 23 29 "マイリトルポニー"  

  crontabで予約番組の末尾にNGと記入すると該当番組の予約を削除できます。  
  crontabからの操作が面倒ならroutine.listに  

  #チャンネル番号 録画時間 "番組タイトル" NG  

  の書式で削除対象の番組を列挙すると作業が簡単です。  

※注意：  
  実行すると、既存のjobをすべて上書きします。  
  既存のjobがある場合は事前にroutine.listに移してください。  
  $ crontab -l > ~/routine.list などとすると作業が簡単です。  
  また、万一のためにcrontabの定期的なバックアップを必ず行なってください。  

・録画スクリプト  
  $ /home/usrdir/rectv/rectv.sh [チャンネル番号] [時間（分）] ["タイトル"]  
  使用サンプル :  
  $ /home/usrdir/rectv/rectv.sh 20 29 "物語シリーズ_セカンドシーズン"  

  録画スクリプトは[チャンネル番号] [時間（分）] ["タイトル"]を引数として読み込み指定の時間分録画を行います。  


TV Program Generator for PT3 (recdgen.sh)  
TV Recorder for PT3 (rectv.sh)

Command line

TV Program Generator for PT3  
  $ /home/usrdir/rectv/recdgen.sh

TV Recorder for PT3  
  $ /home/usrdir/rectv.sh [ch] [length(minute)] ["title"] [iepg]

  Sample : /home/usrdir/rectv/rectv.sh 20 29 "title" 275088


ライセンス
----------
Copyright &copy; 2013 Mahoroba Shinshi  
Distributed under the [MIT License][mit].  
[MIT]: http://www.opensource.org/licenses/mit-license.php
