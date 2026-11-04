# Brewbook

**ハンドドリップの抽出記録アプリ。豆・レシピ・味を 1 杯ごとに記録し、複数の端末で同期できます。**

**Live demo:** https://kippeitashimo-code.github.io/pourover-log/ （メールアドレスで sign up するとお試しいただけます）

[English](README.md) | 日本語

| Brew Log | 記録フォーム | My Beans | Coffee Setup |
| :---: | :---: | :---: | :---: |
| ![Brew Log](docs/screenshots/log.png) | ![記録フォーム](docs/screenshots/form.png) | ![My Beans](docs/screenshots/beans.png) | ![Coffee Setup](docs/screenshots/setup.png) |

## なぜ作ったか

バリスタとして働く中で、ハンドドリップの味は豆、焙煎からの日数、挽き目、湯温、注ぎ方のわずかな違いで変わることを日々感じていました。毎回の抽出を記録して比べ、うまくいった 1 杯を再現できるようにしたかったのが出発点です。紙のメモや表計算ソフトは検索しづらく、カウンターで手早く書き込むのにも向かなかったため、自分の使い方に合ったツールを作りました。

## 主な機能

- **Brew Log** — 抽出日ごとにまとまったカード表示。豆・ロースター・産地・メモで検索、カレンダーで日付を絞り込み、新しい順・古い順・総合評価順で並べ替え。
- **記録フォーム** — 豆、粉量、湯量、比率（自動計算）、湯温、挽き目、注湯とそのメモ、テイスティング評価（総合 1–10、ボディ・酸味・甘さ・苦味・クリアさ 1–5）、写真。
- **Brew again** — 過去のレシピをコピーして新しい記録に。日付は今日、評価と写真は空の状態で始まります。
- **My Beans** — 手持ちの豆の一覧。焙煎からの日数と写真つき。豆を選ぶと記録フォームに詳細が入ります。「過去の記録から追加」で、既存の記録から一覧を作れます。
- **Coffee Setup** — ドリッパー、グラインダー、フィルター、その他の器具（ケトル、スケールなど）を登録し、記録フォームのプルダウンから選択。過去の記録で使った器具は削除せず archive します。
- **同期** — メールでログインすると、スマホと PC で同じデータを使えます。
- **バックアップ** — JSON の export / import。
- **スマホ前提の UI** — 下部の tab bar と、片手で押せる「+」ボタン。

## 技術構成とその理由

| | 選択 | 理由 |
| --- | --- | --- |
| Frontend | `index.html` 1 枚（素の HTML / CSS / JavaScript）、build なし | 規模が小さく、1 ファイルなら読む・直す・deploy するのが簡単。GitHub Pages でそのまま配信できます。 |
| Backend | [Supabase](https://supabase.com/)（Auth、Postgres、Storage） | 自前の server を持たずに、ログイン・database・ファイル保存がそろいます。Row Level Security でユーザーごとのデータを分離。 |
| データ構造 | 1 行に 1 つの **jsonb** 列 `data` | フォームに項目を足しても database の migration が不要。table は `id`、`user_id`、`data` だけです。 |
| 評価スケール | 後方互換の読み出し（`overallOf`、`tasteOf`） | 途中で評価の段階を変更しました（星 1–5 → 総合 1–10、テイスティング 1–10 → 1–5）。古い記録は読むときに換算するので、保存済みデータを書き換える必要がありません。 |
| 同期 | 楽観的更新 + localStorage キャッシュ | 保存した瞬間に画面が更新され、起動時はキャッシュから即座に表示してから server の最新データに置き換えます。 |
| 写真 | ブラウザで JPEG に縮小し、保存するのはファイルのパスだけ | upload が軽く、ローカルのキャッシュも小さく保てます。写真は private bucket に置き、signed URL で表示します。 |

### セキュリティ

- すべての table（`brews`、`equipment`、`beans`）で Row Level Security を有効化。各ユーザーは `user_id` が自分の行しか読む・追加する・変更する・削除することができません。
- 写真は private な Storage bucket の、ユーザー ID 名のフォルダに保存。Storage の policy で自分のフォルダ以外にはアクセスできません。
- client のコードにある Supabase の URL と publishable key は公開前提のものです。守りは上記の database 側のルールが担っています。

詳しくは [`supabase/setup.sql`](supabase/setup.sql) を参照してください。

## ローカルで動かす

```sh
python3 -m http.server 8000   # http://localhost:8000 を開く
```

ファイルを直接開くのではなく、ローカル server を使ってください。sign up の確認メールはページの URL に戻るため、`file://` では動きません。

### 自分の Supabase project で動かす

1. Supabase で project を作成。
2. SQL Editor に [`supabase/setup.sql`](supabase/setup.sql) を全部貼り付けて実行（何度実行しても安全です）。
3. `index.html` の `SUPABASE_URL` と `SUPABASE_KEY` を、自分の project の URL と publishable key に置き換え。
4. Authentication → URL Configuration の Redirect URLs に、アプリの URL（例: `http://localhost:8000/**`）を追加。

## 今後やりたいこと

- 同じ豆の記録を並べて比べる画面やグラフ
- レシピに沿って案内する注湯タイマー
- オフラインでの編集と、あとから同期する仕組み
- PWA としてホーム画面にインストール
- 1 つのレシピを共有できるリンク
- 評価の換算や同期ロジックの自動テスト
