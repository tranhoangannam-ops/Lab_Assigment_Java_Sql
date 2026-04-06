/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 */

package javaone.slide5_inputoutput;

import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;

/**
 *
 * @author Admin
 */
public class Slide5_InputOutput {

    public static void main(String[] args) {
        /* 1. Ghi file */
        try{
        FileWriter fw = new FileWriter("vidu1.txt", true);
        fw.writer(str:"xin chào các bạn !!!!\n")
        fw.writer(str:"Xin chào các bạn!!!!!\n");
        fw.writer("Xin chào các bạn!!!!!\n");
        fw.writer("Xin chào các bạn!!!!!\n");
        fw.close();
        System.out.println("Ghi file thành công");
        }catch(IOException ex) {
            System.out.println("Lỗi: " + ex.getMessage());
        }   
        /* 2. Đọc file */
        try {
         FileReader fr = new FileReader("vidu1.txt");  
         int ch;
         while((ch = fr.read()) != -1) {
             System.out.print((char)ch);
         }
         fr.close();
         System.out.println("Đọc file thành công.");
        }
        catch(IOException ex) {
            System.out.println("Lỗi: " + ex.getMessage());
        }
    }
}
    public static void FileWriterReader () {
/* 1. Ghi file */
        try{
        FileWriter fw = new FileWriter("vidu1.txt", true);
        fw.writer(str:"xin chào các bạn !!!!\n")
        fw.writer(str:"Xin chào các bạn!!!!!\n");
        fw.writer("Xin chào các bạn!!!!!\n");
        fw.writer("Xin chào các bạn!!!!!\n");
        fw.close();
        System.out.println("Ghi file thành công");
        }catch(IOException ex) {
            System.out.println("Lỗi: " + ex.getMessage());
        }   
        /* 2. Đọc file */
        try {
         FileReader fr = new FileReader("vidu1.txt");  
         int ch;
         while((ch = fr.read()) != -1) {
             System.out.print((char)ch);
         }
         fr.close();
         System.out.println("Đọc file thành công.");
        }
        catch(IOException ex) {
            System.out.println("Lỗi: " + ex.getMessage());
        }
    }
}
}

