
import java.io.BufferedReader;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.List;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Trang
 */
public class FixFile {
    public static void main(String args[]) {            
        String inDir = "Test case 2/raw/";
        String ctpDir = "Test case 2/ctp-15/";
        String disonDir = "Test case 2/dison-15/";
        
        int numNodes = 1;
        int numQueries = 1;
        
        FileInputStream fis = null;
        BufferedReader reader = null;
        
        FileWriter outFile = null;
        PrintWriter out = null;
        
        String fn,fo;
        List<String> data1 = new ArrayList<String>();
        List<String> data2 = new ArrayList<String>();
        
        for (int i = 1; i <= numQueries; i++)
        {
            for (int j = 0; j < numNodes; j++)
            {
                fn = inDir + i + "_" + j + ".txt";
                long f = 0;
                long oldf = -1;
                boolean skip = false;
                try {
                    fis = new FileInputStream(fn);
                    reader = new BufferedReader(new InputStreamReader(fis));
                    
                    String line = reader.readLine();
                    while (line != null) {
                        String[] list = line.split(" ");
                        f = Long.parseLong(list[2]);
                        if (!skip)
                        {
                            if (oldf < f)
                            {
                                data1.add(line);
                                oldf = f;
                            }
                            else
                            {
                                System.out.println("Fix");
                                data2.add(line);
                                skip = true;
                            }
                        }
                        else
                        {
                            data2.add(line);
                        }
                        line = reader.readLine();
                    }
                    
                    for (int k = 0;k < data1.size(); k++)
                    {
                        //System.out.println(data1.toArray()[k]);
                    }
                }
               catch (FileNotFoundException ex) {
                    System.out.println("File not found " + fn);
                } catch (IOException ex) {
                    System.out.println(ex.getMessage());
                }
            }
        }
    }
}
