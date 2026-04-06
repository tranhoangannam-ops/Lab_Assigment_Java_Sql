/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package bai2;

import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;

/**
 *
 * @author Admin
 */
public class QuanLySinhVien {

    public record Student(String id, String name, double gpa) {
        public Student {
            if (gpa < 0 || gpa > 4.0) {
                throw new IllegalArgumentException("GPA khong hop le!");
            }
        }

        public boolean isScholarshipEligible() {
            return gpa >= 3.2;
        }
    }

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        List<Student> list = new ArrayList<>();

        System.out.print("Nhap so luong sinh vien: ");
        int n = Integer.parseInt(sc.nextLine());

        for (int i = 0; i < n; i++) {
            System.out.println("---- Sinh vien " + (i + 1) + " ----");

            System.out.print("ID: ");
            String id = sc.nextLine();

            System.out.print("Ten: ");
            String name = sc.nextLine();

            double gpa;
            while (true) {
                try {
                    System.out.print("GPA: ");
                    gpa = Double.parseDouble(sc.nextLine());
                    list.add(new Student(id, name, gpa));
                    break;
                } catch (NumberFormatException e) {
                    System.out.println("❌ GPA khong hop le, nhap lai!");
                }
            }
        }

        System.out.println("\n=== Sinh vien du hoc bong ===");
        for (Student s : list) {
            if (s.isScholarshipEligible()) {
                System.out.println(s);
            }
        }
    }
}