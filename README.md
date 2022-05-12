# phoenix-with-aws-copilot

Phoenix を AWS Copilot で AWS クラウド上にデプロイするサンプル

## サンプルアプリケーション

以下のコマンドで生成したもの

```bash
mix phx.new sample_app --no-ecto
```

外部からアクセスできるように `sample_app/dev.exs` の 12行目を変更

- 変更前

  ```exs
    http: [ip: {127, 0, 0, 1}, port: 4000],
  ```

- 変更後

  ```exs
    http: [ip: {0, 0, 0, 0}, port: 4000],
  ```

## ローカルで動かす

### ローカル動作に必要なアプリケーション

[asdf]

### ローカルへの Elixirのインストール

```bash
asdf plugin add elixir
asdf install
```

### ローカルでの Phoenix の起動

```bash
cd sample_app
mix setup
mix phx.server
```

<http://localhost:4000> にアクセスする

## Docker で動かす

### Docker 動作に必要なアプリケーション

[Docker]

macOS や Windows で無償利用したい場合は [Rancher Desktop][rd] の利用がおすすめ

### ビルド時の不要ファイル削除

ローカル実行時の `deps` や `_build` を削除する

```bash
rm -rf deps _build
```

### コンテナの起動

```bash
docker compose up
```

<http://localhost:4000> にアクセスする

## AWS 上で動かす

### AWS へのデプロイに必要なアプリケーション

[AWS Copilot CLI][copilot]

### 必要な IAM パーミッション

以下のような IAM パーミッション（推定）を持つユーザーで実行する

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Fulls",
            "Effect": "Allow",
            "Action": [
                "cloudformation:*"
                "cloudtrail:LookupEvents",
                "codebuild:ListProjects",
                "codestar-connections:CreateConnection",
                "codestar-connections:ListConnections",
                "codestar-connections:PassConnection",
                "codestar-connections:TagResource",
                "codestar-connections:UntagResource"
                "iam:*",
                "ec2:*",
                "ecr:*",
                "ecs:CreateCluster",
                "s3:*",
                "secretsmanager:DescribeSecret",
                "servicediscovery:*"
            ],
            "Resource": "*"
        },
        {
            "Sid": "ECRCreateRole",
            "Effect": "Allow",
            "Action": [
                "iam:CreateServiceLinkedRole"
            ],
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "replication.ecr.amazonaws.com"
                    ]
                }
            }
        },
        {
            "Sid": "CodeStarConnections",
            "Effect": "Allow",
            "Action": [
                "codestar-connections:DeleteConnection",
                "codestar-connections:GetConnection"
            ],
            "Resource": [
                "arn:aws:codestar-connections:*:<アカウントID>:connection/*"
            ]
        },
        {
            "Sid": "CodeBuild",
            "Effect": "Allow",
            "Action": [
                "codebuild:CreateProject",
                "codebuild:DeleteProject",
                "codebuild:UpdateProject"
            ],
            "Resource": [
                "arn:aws:codebuild:*:<アカウントID>:project/*"
            ]
        },
        {
            "Sid": "ECS",
            "Effect": "Allow",
            "Action": [
                "ecs:DeleteCluster",
                "ecs:DescribeClusters"
            ],
            "Resource": "arn:aws:ecs:*:<アカウントID>:cluster/*"
        },
        {
            "Sid": "SSM",
            "Effect": "Allow",
            "Action": [
                "ssm:DeleteParameter",
                "ssm:DeleteParameters",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:GetParametersByPath",
                "ssm:PutParameter"
            ],
            "Resource": "arn:aws:ssm:*:<アカウントID>:parameter/*"
        },
        {
            "Sid": "STS",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": "arn:aws:iam::<アカウントID>:role/*"
        }
    ]
}
```

### アプリケーションの初期化

アプリケーションとサービスを作成する

まだデプロイはしていない状態

```bash
$ copilot init \
    --app sample-app \
    --name lb-svc \
    --type "Load Balanced Web Service"
Welcome to the Copilot CLI! We're going to walk you through some questions
to help you get set up with a containerized application on AWS. An application is a collection of
containerized services that operate together.

Manifest file for service lb-svc already exists. Skipping configuration.
Ok great, we'll set up a Load Balanced Web Service named lb-svc in application sample-app.

⠴ Creating the infrastructure to manage services and jobs under application sample-app.
```

`lb-svc` サービスは `copilot/lb-svc/manifest.yml` に定義しているものを使う

しばらく待つと以下のように質問される

```text
All right, you're all set for local development.

  Would you like to deploy a test environment? [? for help] (y/N)
```

CloudWatch の Container Insights を使いたいので、ここでは `N` を入力する

`test` 環境を作成する

`<プロファイル名>` の部分だけ自分のプロファイルに変更して実行する

```bash
copilot env init \
  --name test \
  --profile <プロファイル名> \
  --default-config \
  --container-insights
```

作成に数分かかるため、しばらく待つ

以下の表示が出れば `test` 環境が作成できている

```bash
✔ Created environment test in region ap-northeast-1 under application sample-app.
```

### アプリケーションのデプロイ

以下のコマンドでデプロイする

アプリケーションに変更を加えた場合、以降は以下のコマンドだけを実行すればよい

```bash
copilot svc deploy \
  --name lb-svc \
  --env test
```

数分後、以下のように表示されるので、 URL にアクセスする

```text
✔ Deployed service lb-svc.
Recommended follow-up action:
  - You can access your service at http://sampl-Publi-xxx-1316580721.ap-northeast-1.elb.amazonaws.com over the internet.
```

### リソースの変更

copilot/lb-svc/manifest.yml の `cpu` と `memory` を変更することで、
コンテナに割り当てるリソース、コンテナの台数を調整することができる

[ただし、設定できる値の組み合わせには制限がある][resource]

```yml
cpu: 256       # Number of CPU units for the task.
memory: 512    # Amount of memory in MiB used by the task.
count: 1       # Number of tasks that should be running in your service.
```

### アプリケーションの削除

以下のコマンドでアプリケーション、環境、サービスを全て削除する

アプリケーションを削除しないと課金され続けるので注意

```bash
> copilot app delete
...
✔ Deleted service lb-svc from environment test.
✔ Deleted resources of service lb-svc from application sample-app.
✔ Deleted service lb-svc from application sample-app.
✔ Deleted environment test from application sample-app.
✔ Cleaned up deployment resources.
✔ Deleted application resources.
✔ Deleted application configuration.
✔ Deleted local .workspace file.
```

[asdf]: https://github.com/asdf-vm/asdf
[docker]: https://www.docker.com/
[rd]: https://rancherdesktop.io/
[copilot]: https://aws.github.io/copilot-cli/ja/
[resource]: https://docs.aws.amazon.com/ja_jp/AmazonECS/latest/developerguide/task-cpu-memory-error.html
