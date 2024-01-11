# kimppakyyti

Carpool application for mobile devices. 

Bachelor's thesis project. Work in progress.

## configure

git clone git@github.com:teskola/kimppakyyti.git kimppakyyti

flutter create --org com.teskola --platforms=android kimppakyyti

cd kimppakyyti

flutter pub get --no-example

flutterfire configure

mkdir .vscode
cd .vscode
touch launch.json

```
{
    "configurations": [
        {
            "name": "Flutter",
            "type": "dart",
            "request": "launch",
            "toolArgs": [
                "--dart-define",
                "API_KEY=XXXXXX",
                "--dart-define",
                "ROUTES=XXXXXXX"
            ]
        }
    ]
}
```
