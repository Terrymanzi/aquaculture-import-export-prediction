from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, validator
import joblib
import pandas as pd
import numpy as np
from typing import Dict, Union
import uvicorn

# Initialize FastAPI app
app = FastAPI(
    title="Aquaculture Trade Prediction API",
    description="API for predicting aquaculture import and export volumes for African countries",
    version="1.0.0"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify actual origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load model and components at startup
try:
    model = joblib.load('best_model.pkl')
    scaler = joblib.load('scaler.pkl')
    le_country = joblib.load('country_encoder.pkl')
    le_commodity = joblib.load('commodity_encoder.pkl')
    model_metadata = joblib.load('model_metadata.pkl')
    print("Models and components loaded successfully!")
except Exception as e:
    print(f"Error loading models: {e}")
    model = None

# Define valid countries from the encoder
VALID_COUNTRIES = []
if le_country is not None:
    VALID_COUNTRIES = list(le_country.classes_)

# Pydantic models for request/response validation
class PredictionRequest(BaseModel):
    country: str = Field(..., description="Name of the African country", example="Egypt")
    year: int = Field(..., description="Year for prediction", ge=2000, le=2050, example=2025)
    
    @validator('country')
    def validate_country(cls, v):
        if not v:
            raise ValueError("Country name cannot be empty")
        # Title case for consistency
        v = v.title()
        if VALID_COUNTRIES and v not in VALID_COUNTRIES:
            raise ValueError(
                f"Invalid country. Valid countries are: {', '.join(sorted(VALID_COUNTRIES[:10]))}..."
            )
        return v
    
    @validator('year')
    def validate_year(cls, v):
        if v < 2000:
            raise ValueError("Year must be 2000 or later")
        if v > 2050:
            raise ValueError("Year cannot exceed 2050")
        return v

class PredictionResponse(BaseModel):
    country: str
    year: int
    export_volume: float = Field(..., description="Predicted export volume in tonnes")
    import_volume: float = Field(..., description="Predicted import volume in tonnes")
    unit: str = "tonnes"
    confidence_level: str = Field(default="medium", description="Confidence level of prediction")
    
class ErrorResponse(BaseModel):
    error: str
    detail: str

class HealthResponse(BaseModel):
    status: str
    model_loaded: bool
    model_type: str
    available_countries_count: int

# Helper function for predictions
def make_prediction(country: str, year: int) -> Dict[str, Union[str, float]]:
    """Make aquaculture trade predictions for a given country and year."""
    
    if model is None:
        raise HTTPException(status_code=503, detail="Model not loaded")
    
    # Check if country is valid
    if country not in le_country.classes_:
        raise HTTPException(
            status_code=400, 
            detail=f"Country '{country}' not found. Available countries: {', '.join(sorted(VALID_COUNTRIES[:10]))}..."
        )
    
    # Prepare predictions
    predictions = {
        'Export': 0.0,
        'Import': 0.0
    }
    
    # Predict for each trade flow
    for flow_name, is_export in [('Export', 1), ('Import', 0)]:
        total_quantity = 0
        
        # Predict for each commodity
        for commodity in le_commodity.classes_:
            # Create feature vector
            features = pd.DataFrame({
                'Years_Since_2000': [year - 2000],
                'Country_Encoded': [le_country.transform([country])[0]],
                'Commodity_Encoded': [le_commodity.transform([commodity])[0]],
                'Is_Export': [is_export],
                'Quantity_Lag1': [0],  # Simplified - would need historical data
                'Quantity_MA3': [0]    # Simplified - would need historical data
            })
            
            # Scale features
            features_scaled = scaler.transform(features)
            
            # Make prediction
            quantity_pred = model.predict(features_scaled)[0]
            quantity_pred = max(0, quantity_pred)  # Ensure non-negative
            
            total_quantity += quantity_pred
        
        predictions[flow_name] = round(total_quantity, 2)
    
    # Determine confidence level based on year distance from training data
    years_ahead = year - 2015  # Assuming training data ends at 2015
    if years_ahead <= 5:
        confidence = "high"
    elif years_ahead <= 10:
        confidence = "medium"
    else:
        confidence = "low"
    
    return {
        'country': country,
        'year': year,
        'export_volume': predictions['Export'],
        'import_volume': predictions['Import'],
        'unit': 'tonnes',
        'confidence_level': confidence
    }

# API Endpoints

@app.get("/", response_model=Dict[str, str])
async def root():
    """Welcome endpoint with API information."""
    return {
        "message": "Welcome to the Aquaculture Trade Prediction API",
        "documentation": "/docs",
        "health_check": "/health"
    }

@app.get("/health", response_model=HealthResponse)
async def health_check():
    """Check if the API and model are operational."""
    return {
        "status": "healthy" if model is not None else "unhealthy",
        "model_loaded": model is not None,
        "model_type": model_metadata.get('model_type', 'Unknown') if model_metadata else 'Unknown',
        "available_countries_count": len(VALID_COUNTRIES)
    }

@app.post("/predict", response_model=PredictionResponse)
async def predict(request: PredictionRequest):
    """
    Predict aquaculture import and export volumes for a given country and year.
    
    - **country**: Name of the African country (e.g., "Egypt", "Nigeria")
    - **year**: Year for prediction (between 2000 and 2050)
    
    Returns predicted export and import volumes in tonnes.
    """
    try:
        result = make_prediction(request.country, request.year)
        return PredictionResponse(**result)
    except HTTPException as e:
        raise e
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Prediction error: {str(e)}")

@app.get("/countries", response_model=Dict[str, list])
async def get_countries():
    """Get list of available countries for prediction."""
    return {
        "countries": sorted(VALID_COUNTRIES),
        "total": len(VALID_COUNTRIES)
    }

@app.get("/model-info", response_model=Dict[str, Union[str, Dict]])
async def get_model_info():
    """Get information about the trained model."""
    if model_metadata is None:
        raise HTTPException(status_code=503, detail="Model metadata not available")
    
    return {
        "model_type": model_metadata.get('model_type', 'Unknown'),
        "features": model_metadata.get('features', []),
        "performance": model_metadata.get('performance', {}),
        "training_date": model_metadata.get('training_date', 'Unknown')
    }

@app.post("/batch-predict", response_model=Dict[str, list])
async def batch_predict(requests: list[PredictionRequest]):
    """
    Make predictions for multiple country-year combinations.
    
    Accepts a list of prediction requests and returns all predictions.
    """
    if len(requests) > 100:
        raise HTTPException(status_code=400, detail="Maximum 100 predictions per batch")
    
    results = []
    errors = []
    
    for idx, request in enumerate(requests):
        try:
            result = make_prediction(request.country, request.year)
            results.append(result)
        except Exception as e:
            errors.append({
                "index": idx,
                "country": request.country,
                "year": request.year,
                "error": str(e)
            })
    
    return {
        "predictions": results,
        "errors": errors,
        "total_success": len(results),
        "total_errors": len(errors)
    }

# Error handlers
@app.exception_handler(ValueError)
async def value_error_handler(request, exc):
    return JSONResponse(
        status_code=400,
        content={"error": "Invalid input", "detail": str(exc)}
    )

@app.exception_handler(HTTPException)
async def http_exception_handler(request, exc):
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": exc.detail, "detail": str(exc)}
    )

# Run the application
if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)