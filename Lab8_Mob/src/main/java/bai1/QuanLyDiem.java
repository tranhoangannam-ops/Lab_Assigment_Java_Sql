/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */

package bai1;
import java.util.ArrayList;
import java.util.Scanner;

/**
 *
 * @author Admin
 */
public class QuanLyDiem {

 public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        ArrayList<Integer> list = new ArrayList<>();

        System.out.println("Nhap diem:");

        for (int i = 0; i < 5; i++) {
            System.out.print("Diem " + (i + 1) + ": ");
            String input = sc.nextLine();

            if (input.isEmpty()) {
                list.add(null);
            } else {
                list.add(Integer.valueOf(input)); 
            }
        }

        System.out.println("Danh sach diem: " + list);

        double sum = 0;
        int count = 0;

        for (Integer d : list) {
            if (d != null) { 
                sum += d; 
                count++;
            }
        }

        double avg = (count == 0) ? 0 : sum/count;
        System.out.println("Diem TB: " + avg);

        if (avg >= 8) System.out.println("Gioi");
        else if (avg >= 6.5) System.out.println("Kha");
        else System.out.println("Trung binh");
    }
}