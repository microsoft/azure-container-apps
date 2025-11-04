import os, json
from flask import Flask, request, Response, render_template_string

APP_ID = os.getenv("APP_ID", "unset")
app = Flask(__name__)

@app.route("/", defaults={"path": ""}, methods=["GET","POST","PUT","PATCH","DELETE","HEAD","OPTIONS"])
@app.route("/<path:path>", methods=["GET","POST","PUT","PATCH","DELETE","HEAD","OPTIONS"])
def catch_all(path):
    body = request.get_data(as_text=True)
    resp = {
        "app_id": APP_ID,
        "method": request.method,
        "path": "/" + path,
        "args": request.args.to_dict(flat=False),
        "headers": dict(request.headers),
        "body": body,
    }
    # If client accepts HTML, show pretty template
    if "text/html" in request.headers.get("Accept", ""):
        template = '''
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
            <title>App Info</title>
            <style>
                body { background: #f8f9fa; }
                .card { margin-top: 2rem; }
                .header-foldout { cursor: pointer; }
            </style>
        </head>
        <body>
        <div class="container">
            <div class="card shadow">
                <div class="card-header bg-primary text-white">
                    <h3>App Info</h3>
                </div>
                <div class="card-body">
                    <ul class="list-group list-group-flush mb-3">
                        <li class="list-group-item"><strong>App ID:</strong> {{ app_id }}</li>
                        <li class="list-group-item"><strong>Method:</strong> {{ method }}</li>
                        <li class="list-group-item"><strong>Path:</strong> {{ path }}</li>
                        <li class="list-group-item"><strong>Args:</strong>
                            <ul>
                            {% for k, v in args.items() %}
                                <li><strong>{{ k }}:</strong> {{ v }}</li>
                            {% else %}
                                <li><em>No args</em></li>
                            {% endfor %}
                            </ul>
                        </li>
                    </ul>
                    <div class="accordion" id="headersAccordion">
                        <div class="accordion-item">
                            <h2 class="accordion-header" id="headingHeaders">
                                <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapseHeaders" aria-expanded="false" aria-controls="collapseHeaders">
                                    Show Headers
                                </button>
                            </h2>
                            <div id="collapseHeaders" class="accordion-collapse collapse" aria-labelledby="headingHeaders" data-bs-parent="#headersAccordion">
                                <div class="accordion-body">
                                    <ul>
                                    {% for k, v in headers.items() %}
                                        <li><strong>{{ k }}:</strong> {{ v }}</li>
                                    {% endfor %}
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="mt-3">
                        <strong>Body:</strong>
                        <pre class="bg-light p-2 border rounded">{{ body }}</pre>
                    </div>
                </div>
            </div>
        </div>
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        </body>
        </html>
        '''
        return render_template_string(template, **resp)
    return Response(json.dumps(resp), mimetype="application/json")
