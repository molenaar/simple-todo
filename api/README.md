# Azure Functions API Template

This directory serves as a placeholder for Azure Functions API endpoints.

## Structure

When you set up Azure Functions with this template, your API structure will look like:

```
api/
├── function_app.py           # Main Azure Functions entry point (Python v2 model)
├── requirements.txt          # Python dependencies
├── host.json                # Azure Functions host configuration
├── local.settings.json      # Local development settings (not in git)
└── README.md               # This file
```

## Getting Started

1. **Initialize Azure Functions**
   ```powershell
   # Run the SWA initialization script which will set up the API
   .\4-swa-init.ps1
   ```

2. **Python v2 Model**
   The template uses Azure Functions Python v2 programming model with decorators:
   ```python
   import azure.functions as func
   
   app = func.FunctionApp()
   
   @app.function_name(name="HttpExample")
   @app.route(route="hello", auth_level=func.AuthLevel.ANONYMOUS)
   def http_example(req: func.HttpRequest) -> func.HttpResponse:
       return func.HttpResponse("Hello from Azure Functions!")
   ```

3. **Local Development**
   ```powershell
   # Start the API server (from project root)
   npm run dev:api
   ```

## Integration with Astro

The API integrates seamlessly with the Astro frontend through:
- **Development**: SWA CLI proxy (`npm run dev:swa`)
- **Build-time**: Fetch API data during static generation
- **Production**: Direct Azure Functions integration

## Configuration

Key configuration files:
- **host.json**: Azure Functions runtime settings
- **requirements.txt**: Python package dependencies
- **local.settings.json**: Local environment variables

## Next Steps

After running `4-swa-init.ps1`, this placeholder will be replaced with a complete Azure Functions setup including:
- ✅ Python v2 function app structure
- ✅ Host configuration with durable functions support
- ✅ Development environment setup
- ✅ Example HTTP endpoints
- ✅ Local debugging configuration

---

*This is a template placeholder. The actual API structure will be created when you run the SWA initialization script.*
