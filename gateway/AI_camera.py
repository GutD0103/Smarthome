from keras.models import load_model
import cv2
import numpy as np

class AI_CAM:
    def __init__(self, model_path, labels_path, camera_index=0):
        self.model = load_model(model_path, compile=False)
        self.class_names = self.load_labels(labels_path)
        self.camera = cv2.VideoCapture(camera_index)

    @staticmethod
    def load_labels(labels_path):
        with open(labels_path, "r") as file:
            return file.readlines()

    def preprocess_image(self, image):
        image = cv2.resize(image, (224, 224), interpolation=cv2.INTER_AREA)
        image = np.asarray(image, dtype=np.float32).reshape(1, 224, 224, 3)
        image = (image / 127.5) - 1
        return image

    def predict_image(self, image):
        prediction = self.model.predict(image)
        index = np.argmax(prediction)
        class_name = self.class_names[index]
        confidence_score = prediction[0][index]
        return class_name, confidence_score

    def run(self):
        while True:
            ret, image = self.camera.read()
            cv2.imshow("Webcam Image", image)

            preprocessed_image = self.preprocess_image(image)
            class_name, confidence_score = self.predict_image(preprocessed_image)

            print("Class:", class_name[2:], end="")
            print("Confidence Score:", str(np.round(confidence_score * 100))[:-2], "%")

            keyboard_input = cv2.waitKey(1)
            if keyboard_input == 27:  # ASCII for the esc key
                break

        self.camera.release()
        cv2.destroyAllWindows()

if __name__ == "__main__":
    classifier = AI_CAM("model/keras_model.h5", "model/labels.txt", camera_index=0)
    classifier.run()
