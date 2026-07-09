# Forecasting Module Documentation

## Purpose and Justification

The forecasting module provides predictive analytics to help donors and NGOs make informed decisions about food distribution and resource planning.

### Key Benefits

1. **Demand Prediction** - Predicts future food demand based on historical patterns
2. **Waste Reduction** - Helps donors understand when and how much to donate
3. **Resource Planning** - Assists NGOs in planning their collection and distribution schedules
4. **Seasonal Insights** - Identifies seasonal trends in food availability and demand

## Historical Data Storage

### Database Schema

#### Collection: `donation_history`
```
{
  "id": String,
  "donorId": String,
  "foodType": String,
  "quantity": Number,
  "unit": String,
  "location": GeoPoint,
  "timestamp": Timestamp,
  "status": String, // completed, expired, cancelled
  "claimCount": Number,
  "timeToClaim": Number, // in hours
  "timeToComplete": Number // in hours
}
```

#### Collection: `claim_history`
```
{
  "id": String,
  "donationId": String,
  "claimantId": String,
  "quantity": Number,
  "timestamp": Timestamp,
  "fulfillmentTime": Timestamp,
  "location": GeoPoint
}
```

#### Collection: `demand_patterns`
```
{
  "id": String,
  "region": String,
  "foodType": String,
  "dayOfWeek": Number,
  "month": Number,
  "averageDemand": Number,
  "peakHours": Array<Number>,
  "lastUpdated": Timestamp
}
```

### Data Collection Points

1. **On Donation Creation** - Food type, quantity, location, time
2. **On Claim Acceptance** - Response time, claimant location
3. **On Donation Completion** - Fulfillment time, remaining quantity
4. **On Donation Expiry** - Unclaimed quantity, reasons

## Prediction Methodology

### 1. Time Series Analysis
- Uses historical donation data to identify patterns
- Analyzes day-of-week and time-of-day trends
- Seasonal decomposition for long-term trends

### 2. Demand Forecasting
- Predicts food demand by type and location
- Uses exponential smoothing for short-term predictions
- ARIMA models for medium-term forecasts

### 3. Supply-Demand Matching
- Predicts optimal donation times
- Suggests food types with high demand
- Recommends donation quantities

### 4. Waste Prediction
- Identifies food types with high expiry rates
- Predicts likelihood of donation being claimed
- Suggests expiry times to minimize waste

## Implementation Files

### Core Services
- `lib/services/forecast_service.dart` - Basic forecasting logic
- `lib/services/enhanced_forecast_service.dart` - Advanced ML predictions
- `lib/services/analytics_service.dart` - Historical data aggregation

### UI Components
- `lib/screens/forecast/forecast_dashboard.dart` - Forecasting dashboard
- `lib/screens/forecast/ai_forecast_dashboard.dart` - AI-powered insights
- `lib/widgets/forecast_chart.dart` - Visualization components

## Usage Examples

### For Donors
```dart
// Get optimal donation time
final forecast = await ForecastService().getDonationForecast(
  foodType: 'Rice',
  location: userLocation,
);

// Shows: "Best time to donate: Tuesday 10AM-12PM"
// Shows: "Expected claim time: 2-3 hours"
```

### For NGOs
```dart
// Get demand forecast
final demand = await ForecastService().getDemandForecast(
  region: 'Karachi',
  daysAhead: 7,
);

// Shows weekly demand chart
// Shows peak collection times
```

## Future Enhancements

1. **Machine Learning Integration** - Use TensorFlow Lite for on-device predictions
2. **Weather Integration** - Factor weather patterns into forecasts
3. **Event Detection** - Identify festivals/events affecting demand
4. **Collaborative Filtering** - Learn from similar users' patterns

## Research Value

This module contributes to:
- **Food waste research** - Quantifies waste patterns
- **Urban food security** - Maps food availability
- **Behavioral analysis** - Studies donor/recipient patterns
- **Resource optimization** - Improves distribution efficiency

## Performance Metrics

- **Prediction Accuracy**: Target 75-80% for 24-hour forecasts
- **Update Frequency**: Patterns recalculated daily
- **Historical Data Retention**: 2 years minimum
- **Query Performance**: <2 seconds for dashboard loads