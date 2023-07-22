# AzooKeyKanakanjiConverter

azooKeyのかな漢字変換モジュールを切り出したライブラリです。

## KanaKanjiConverterModule
かな漢字変換を受け持つモジュールです。

```swift
import KanaKanjiConverterModule

// 変換器を初期化する
let converter = KanaKanjiConverter()
// 入力を初期化する
var c = ComposingText()
// 変換したい文章を追加する
c.insertAtCursorPosition("あずーきーはしんじだいのきーぼーどあぷりです", inputStyle: .direct)
// 変換のためのオプションを指定して、変換を要求
let results = converter.requestCandidates(c, options: ConvertRequestOptions(...))
// 結果の一番目を表示
print(results.mainResults.first!.text)  // azooKeyは新時代のキーボードアプリです
```
`ConvertRequestOptions`は、変換リクエストに必要な情報を指定します。詳しくはコードに書かれたドキュメントコメントを参照してください。

### 辞書データ

利用時は、ConvertRequestOptionsの`dictionaryResourceURL`に辞書データのディレクトリのURLを指定する必要があります。

辞書データは[Google Drive](https://drive.google.com/drive/folders/1Kh7fgMFIzkpg7YwP3GhWTxFkXI-yzT9E?usp=sharing)からダウンロードすることができます。

また、以下のフォーマットであれば自前で用意した辞書データを利用することもできます。カスタム辞書データのサポートは限定的なので、ソースコードを確認の上ご利用ください。

```
- Dictionary/
  - louds/
    - charId.chid
    - X.louds
    - X.loudschars2
    - X.loudstxt3
    - ...
  - p/
    - X.csv
  - cb/
    - 0.binary
    - 1.binary
    - ...
  - mm.binary
```

## SwiftUtils
Swift一般に利用できるユーティリティのモジュールです。
