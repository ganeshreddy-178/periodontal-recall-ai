"""
predict.py
Standalone CLI prediction script for a single dental image.

Usage:
    python predict.py --image /path/to/image.jpg --model models_saved/periodontal_cnn_model.h5
"""
import argparse
import numpy as np
import cv2
import tensorflow as tf

CLASSES  = ["Healthy", "Mild Periodontitis", "Moderate Periodontitis", "Severe Periodontitis"]
IMG_SIZE = 224


def preprocess(path: str) -> np.ndarray:
    img = cv2.imread(path)
    if img is None:
        raise FileNotFoundError(f"Cannot read: {path}")
    img   = cv2.resize(img, (IMG_SIZE, IMG_SIZE))
    lab   = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l     = clahe.apply(l)
    img   = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    img   = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
    return (img.astype(np.float32) / 255.0)[np.newaxis]


def main(args):
    print(f"Loading model: {args.model}")
    model = tf.keras.models.load_model(args.model)

    print(f"Processing image: {args.image}")
    x     = preprocess(args.image)
    probs = model.predict(x, verbose=0)[0]

    print("\n--- Prediction Results ---")
    for cls, p in zip(CLASSES, probs):
        bar = "█" * int(p * 40)
        print(f"  {cls:<30} {p*100:5.2f}%  {bar}")

    best_idx = int(np.argmax(probs))
    print(f"\n  Diagnosis : {CLASSES[best_idx]}")
    print(f"  Confidence: {probs[best_idx]*100:.2f}%")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict periodontal severity from image")
    parser.add_argument("--image", required=True)
    parser.add_argument("--model", default="models_saved/periodontal_cnn_model.h5")
    main(parser.parse_args())
