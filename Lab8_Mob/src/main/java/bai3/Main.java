/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package bai3;
/**
 *
 * @author Admin
 */
@Developer(name = "Khoa", version = "1.0")
public class Main {
  public static void main(String[] args) {

        Manager m = new Manager();
        System.out.println("Luong: " + m.getSalaryNew());

        // Reflection đọc annotation
        if (Main.class.isAnnotationPresent(Developer.class)) {
            Developer dev = Main.class.getAnnotation(Developer.class);
            System.out.println("Developer: " + dev.name());
            System.out.println("Version: " + dev.version());
        }
    }
}