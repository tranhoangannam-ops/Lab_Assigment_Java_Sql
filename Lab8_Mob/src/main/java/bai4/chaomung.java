/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Class.java to edit this template
 */
package bai4;

import java.util.Scanner;

/**
 *
 * @author Admin
 */
public class chaomung {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);

        System.out.print("Nhap ten: ");
        String name = sc.nextLine();

        System.out.print("Nhap GPA: ");
        double gpa = Double.parseDouble(sc.nextLine());

        
        String welcome = """
                ===== welcome =====
                Chao mung ban
                ====================
                """;

        System.out.println(welcome);

        String email = """
                Xin chao %s,
                Ban da dang ky thanh cong!
                Cam on ban.
                """.formatted(name);

        System.out.println(email);

        
        String html = """
                <html>
                    <body>
                        <h1>Sinh vien: %s</h1>
                        <p>GPA: %.2f</p>
                    </body>
                </html>
                """.formatted(name, gpa);

        System.out.println(html);

        String sql = """
                SELECT * FROM Student
                WHERE gpa > 3.0;
                """;

        System.out.println(sql);
    }
}