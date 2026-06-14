"""
augmentation.py
Keras ImageDataGenerator-based augmentation pipeline.
"""
import numpy as np
from tensorflow.keras.preprocessing.image import ImageDataGenerator


def get_train_generator(X_train: np.ndarray, y_train: np.ndarray,
                        batch_size: int = 32):
    """Returns an augmented training batch generator."""
    datagen = ImageDataGenerator(
        rotation_range      = 20,
        width_shift_range   = 0.15,
        height_shift_range  = 0.15,
        shear_range         = 0.10,
        zoom_range          = 0.15,
        horizontal_flip     = True,
        vertical_flip       = False,
        brightness_range    = [0.8, 1.2],
        fill_mode           = "nearest",
    )
    from tensorflow.keras.utils import to_categorical
    y_cat = to_categorical(y_train, num_classes=4)
    return datagen.flow(X_train, y_cat, batch_size=batch_size, shuffle=True)


def get_val_generator(X_val: np.ndarray, y_val: np.ndarray,
                      batch_size: int = 32):
    """Returns a validation generator (no augmentation)."""
    datagen = ImageDataGenerator()
    from tensorflow.keras.utils import to_categorical
    y_cat = to_categorical(y_val, num_classes=4)
    return datagen.flow(X_val, y_cat, batch_size=batch_size, shuffle=False)
