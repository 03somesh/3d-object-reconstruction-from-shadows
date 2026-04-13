"""
3D Object Height Reconstruction from Shadow
Dataset: Shadow Physics Dataset (generated from real-world formulas)
Model: Linear Regression (sklearn)
Target: Predict object HEIGHT from shadow measurements + sun angle
"""

import pandas as pd
import numpy as np
import json
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score

# ── 1. Load Dataset ─────────────────────────────────────────────
df = pd.read_csv('shadow_dataset.csv')

print("=" * 60)
print("3D OBJECT HEIGHT RECONSTRUCTION FROM SHADOW")
print("         Linear Regression Model")
print("=" * 60)
print(f"\nDataset shape : {df.shape}")
print(f"Target (height): min={df['object_height_m'].min():.2f}m  "
      f"max={df['object_height_m'].max():.2f}m  "
      f"mean={df['object_height_m'].mean():.2f}m")

# ── 2. Features & Target ─────────────────────────────────────────
FEATURES = [
    'sun_elevation_deg', 'sun_azimuth_deg', 'time_of_day_hr',
    'shadow_length_m', 'shadow_width_m', 'shadow_area_m2',
    'aspect_ratio', 'object_type'
]
TARGET = 'object_height_m'

X = df[FEATURES]
y = df[TARGET]

# ── 3. Train-Test Split ─────────────────────────────────────────
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)
print(f"\nTrain size: {len(X_train)}  |  Test size: {len(X_test)}")

# ── 4. Scale ────────────────────────────────────────────────────
scaler = StandardScaler()
X_train_s = scaler.fit_transform(X_train)
X_test_s  = scaler.transform(X_test)

# ── 5. Train Linear Regression ──────────────────────────────────
model = LinearRegression()
model.fit(X_train_s, y_train)

# ── 6. Evaluate ─────────────────────────────────────────────────
y_pred = model.predict(X_test_s)
mae  = mean_absolute_error(y_test, y_pred)
rmse = np.sqrt(mean_squared_error(y_test, y_pred))
r2   = r2_score(y_test, y_pred)
cv   = cross_val_score(model, scaler.transform(X), y, cv=5, scoring='r2').mean()

print(f"\n{'─'*42}")
print(f"  MAE  (Mean Abs Error)  : {mae:.4f} m")
print(f"  RMSE (Root MSE)        : {rmse:.4f} m")
print(f"  R² Score               : {r2:.4f}")
print(f"  5-Fold CV R²           : {cv:.4f}")
print(f"{'─'*42}")

# ── 7. Feature Coefficients ─────────────────────────────────────
coefs = dict(zip(FEATURES, model.coef_))
print("\nFeature Coefficients:")
for feat, coef in sorted(coefs.items(), key=lambda x: abs(x[1]), reverse=True):
    bar  = "█" * int(abs(coef) / max(abs(v) for v in coefs.values()) * 20)
    sign = "+" if coef > 0 else "-"
    print(f"  {feat:<25} {sign}{abs(coef):.4f}  {bar}")

# ── 8. Save metadata ────────────────────────────────────────────
meta = {
    "intercept"   : round(float(model.intercept_), 6),
    "coefficients": {f: round(float(v), 6) for f, v in coefs.items()},
    "scaler_mean" : {f: round(float(v), 6) for f, v in zip(FEATURES, scaler.mean_)},
    "scaler_std"  : {f: round(float(v), 6) for f, v in zip(FEATURES, scaler.scale_)},
    "metrics"     : {"MAE": round(mae,4), "RMSE": round(rmse,4), "R2": round(r2,4), "CV_R2": round(cv,4)},
    "features"    : FEATURES,
    "feature_ranges": {
        f: {"min": round(float(df[f].min()),3),
            "max": round(float(df[f].max()),3),
            "mean": round(float(df[f].mean()),3)}
        for f in FEATURES
    }
}
with open('model_metadata.json', 'w') as fp:
    json.dump(meta, fp, indent=2)

print("\n✅ Saved: model_metadata.json")
print("\nSample Predictions vs Actual:")
print(f"{'Actual':>10}  {'Predicted':>10}  {'Error':>8}")
for a, p in zip(list(y_test[:8]), list(y_pred[:8])):
    print(f"{a:>10.3f}  {p:>10.3f}  {abs(a-p):>8.3f} m")
