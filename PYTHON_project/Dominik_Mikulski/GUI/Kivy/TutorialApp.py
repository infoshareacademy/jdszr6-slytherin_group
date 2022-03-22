from tkinter import VERTICAL
from turtle import color, textinput
from kivy.app import App
from kivy.uix.label import Label
from kivy.uix.scatter import Scatter
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.textinput import TextInput
import random

class ScatterTextWidget(BoxLayout):
    def change_label_color(self,*args):
        my_color = [random.random() for i in range(3)]+[1]
        label = self.ids['my_label']
        label.color = my_color
        label1 = self.ids['label1']
        label1.color=my_color
        label2 = self.ids['label2']
        label2.color=my_color
        
class TutorialApp(App):
    def build(self):
        return ScatterTextWidget()

if __name__ == "__main__":
    TutorialApp().run()