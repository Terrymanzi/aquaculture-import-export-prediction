# Aquaculture Trade Prediction System

A machine learning-powered App for predicting annual aquaculture import and export volumes for African countries.

## Mission

My mission is to empower African fisheries and aquaculture stakeholders with accessible data-driven insights by providing a friendly tool that predicts import and export trade volumes annually.
My goal is to simplify decision-making through machine learning while promoting transparency and planning in regional aquaculture trade.

## Live Demo

🎥 **YouTube Demo**: [Watch the 5-minute demo](https://www.youtube.com/watch?v=mN-Mf0jgRpU)

🔗 **Public API**: [https://aquaculture-import-export-prediction.onrender.com/docs](https://aquaculture-import-export-prediction.onrender.com/docs)

Test the API using the Swagger UI interface at the link above.

## Project Overview

This project implements a complete end-to-end solution for predicting aquaculture trade volumes using:

- **Machine Learning**: Linear Regression, Decision Trees, and Random Forest models
- **API**: FastAPI backend with data validation and CORS support
- **Mobile App**: Flutter application for user-friendly predictions

## Dataset

- **Source**: [Global Fisheries & Aquaculture Department](https://www.kaggle.com/datasets/zhengtzer/global-fisheries-aquaculture-department?select=Africa_Quantity.csv)
- **Focus**: African countries' aquaculture trade data
- **Commodities**: Fish, Crustaceans
- **Time Period**: 2000-2015 (historical data)
- **Predictions**: 2000-2050

## Project Structure

```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   └── multivariate.ipynb          # Main ML notebook
│   │
│   ├── API/
│   │   ├── prediction.py               # FastAPI application
│   │   ├── requirements.txt            # Python dependencies
│   │   ├── best_model.pkl             # Saved ML model
│   │   ├── scaler.pkl                 # Feature scaler
│   │   ├── country_encoder.pkl        # Country label encoder
│   │   ├── commodity_encoder.pkl      # Commodity label encoder
│   │   └── model_metadata.pkl         # Model information
│   │
│   └── FlutterApp/
│       ├── lib/
│       │   └── main.dart              # Flutter application
│       └── pubspec.yaml               # Flutter dependencies
```

## Features

### Machine Learning Model

- **Data Preprocessing**: Handles missing values, outliers, and data reshaping
- **Feature Engineering**:
  - Years since 2000
  - Country and commodity encoding
  - Trade flow indicators (Import/Export)
  - Lag features and moving averages
- **Model Comparison**: Linear Regression (with gradient descent), Decision Trees, Random Forest
- **Visualization**: Loss curves, scatter plots, feature importance

### API Features

- RESTful endpoints for predictions
- Input validation with Pydantic
- CORS middleware for cross-origin requests
- Batch prediction support
- Health check and model info endpoints
- Comprehensive error handling

### Flutter App Features

- Multi-page navigation
- Country autocomplete
- Year validation (2000-2050)
- Real-time prediction results
- Error handling and display
- Confidence level indicators

## Installation & Setup

### 1. Machine Learning Model

```bash
# Install Python dependencies
pip install pandas numpy scikit-learn matplotlib seaborn joblib

# Run the Jupyter notebook
jupyter notebook multivariate.ipynb
```

### 2. API Setup

```bash
cd API/

# Install dependencies
pip install -r requirements.txt

# Run locally
python prediction.py

# API will be available at http://localhost:8000
# Documentation at http://localhost:8000/docs
```

### 3. Mobile App Setup

**Prerequisites:**

- Install [Flutter SDK](https://flutter.dev/docs/get-started/install)
- Install Android Studio or Xcode for device emulation

**Steps:**

```bash
cd FlutterApp/

# Get dependencies
flutter pub get

# Run on Android emulator/device
flutter run

# Or run on iOS simulator (macOS only)
flutter run -d ios

# Or run on web browser
flutter run -d web
```

**Note**: The app is pre-configured to use the public API endpoint.

## API Endpoints

- `GET /` - Welcome message
- `GET /health` - Health check
- `POST /predict` - Single prediction
- `GET /countries` - List available countries
- `GET /model-info` - Model information
- `POST /batch-predict` - Multiple predictions

### Example Request

```bash
curl -X POST "https://aquaculture-import-export-prediction.onrender.com/predict" \
     -H "Content-Type: application/json" \
     -d '{
       "country": "Egypt",
       "year": 2025
     }'
```

### Example Response

```json
{
  "country": "Egypt",
  "year": 2025,
  "export_volume": 12500.5,
  "import_volume": 8750.25,
  "unit": "tonnes",
  "confidence_level": "medium"
}
```

## Model Performance

The system compares multiple models and selects the best performer based on R² score:

- **Linear Regression**: Traditional approach with gradient descent optimization
- **Decision Tree**: Non-linear model capturing complex patterns
- **Random Forest**: Ensemble method for improved accuracy

Key metrics evaluated:

- Mean Squared Error (MSE)
- Root Mean Squared Error (RMSE)
- Mean Absolute Error (MAE)
- R² Score

## Deployment

### Deploy API to Render

1. Push code to GitHub
2. Create new Web Service on Render
3. Connect GitHub repository
4. Configure build and start commands
5. Deploy and get public URL

See `deployment_guide.md` for detailed instructions.

### Deploy Flutter App

Options:

- **Android**: Build APK with `flutter build apk`
- **iOS**: Build IPA with `flutter build ios`
- **Web**: Build with `flutter build web`

## Future Improvements

1. **Data Enhancement**:

   - Include more recent data (2016-2024)
   - Add economic indicators
   - Include climate data

2. **Model Improvements**:

   - Time series models (ARIMA, LSTM)
   - Ensemble methods
   - Hyperparameter optimization

3. **Features**:
   - Historical trend visualization
   - Export reports (PDF/Excel)
   - Multi-language support
   - Offline predictions

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request
