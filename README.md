# kimppakyyti

Carpool application for mobile devices. 

Bachelor's thesis project. Work in progress.

## configure

flutter create --org com.teskola.kimppakyyti --platforms=android .

flutterfire configure

.vscode/launch.json

`{
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
}`
