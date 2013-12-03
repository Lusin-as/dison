/*
 * Copyright (c) 2013, Universitat Pompeu Fabra.
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 	- Redistributions of source code must retain the above copyright
 * 	- notice, this list of conditions and the following disclaimer.
 * 	- Redistributions in binary form must reproduce the above copyright
 * 	  notice, this list of conditions and the following disclaimer in the
 * 	  documentation and/or other materials provided with the distribution.
 * 	- Neither the name of the Universitat Pompeu Fabra nor the 
 * 	  names of its contributors may be used to endorse or promote products 
 * 	  derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL UNIVERSITAT POMPEU FABRA BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Read log files and write to a unique output file
 * @author: Trang Cao Minh
*/

import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.util.regex.Matcher;
import java.util.regex.Pattern;




class NodeInfo {
    private int sent;
    private int recv;
    private long firstReceivedTime;
    private long lastReceivedTime;
    private int redundant;
    private long mana;
    private long routing;
    private int mgAddr;
    private long forward;
    private List<Integer> volData;

    public NodeInfo() {
        sent = 0;
        recv = 0;
        firstReceivedTime = 0;
        lastReceivedTime = 0;
        redundant = 0;
        mana = 0;
        routing = 0;
        mgAddr = 65535;
        forward = 0;
    }

    public int getSent() {
        return sent;
    }

    public void setSent(int sent) {
        this.sent = sent;
    }

    public int getRecv() {
        return recv;
    }

    public void setRecv(int recv) {
        this.recv = recv;
    }
   
    

    public long getFirstReceivedTime() {
        return firstReceivedTime;
    }

    public void setFirstReceivedTime(long firstReceivedTime) {
        this.firstReceivedTime = firstReceivedTime;
    }

    public long getLastReceivedTime() {
        return lastReceivedTime;
    }

    public void setLastReceivedTime(long lastReceivedTime) {
        this.lastReceivedTime = lastReceivedTime;
    }

    public int getRedundant() {
        return redundant;
    }

    public void setRedundant(int redundant) {
        this.redundant = redundant;
    }

    public long getMana() {
        return mana;
    }

    public void setMana(long mana) {
        this.mana = mana;
    }

    public long getRouting() {
        return routing;
    }

    public void setRouting(long routing) {
        this.routing = routing;
    }

    public int getMgAddr() {
        return mgAddr;
    }

    public void setMgAddr(int mgAddr) {
        this.mgAddr = mgAddr;
    }

    public long getForward() {
        return forward;
    }

    public void setForward(long forward) {
        this.forward = forward;
    }

    public List<Integer> getVolData() {
        return volData;
    }

    public void setVolData(List<Integer> volData) {
        this.volData = volData;
    }
    
    
}


public class ReadLogFile {

    final static int NUM_NODES = 26;
    
    
    public static void main(String args[]) {

        String inDir = null, outDir = null;
        String queryid = null;
        String outVol = null;

        if (args.length == 0)
        {
            System.err.println("Please enter the directory to the log files");
            System.exit(1);
        }
        
        if (args.length > 0) {
            System.out.println(args[0]);
            try {
                inDir = args[0];
                if (args.length >= 2)
                {
                    outDir = args[1];
                }
                else {
                    outDir = inDir + "/trace.txt";
                }
                
                if (args.length >= 3)
                {
                    queryid = "/" + args[2] + "_";
                }
                else {
                    queryid = "/0_";
                }
                
                if (args.length >= 4)
                {
                    outVol = args[3];
                }
                
                if (!IsExist(inDir))
                {
                    System.err.println("Directory of log files does not exist");
                    System.exit(1);
                }
                
            } catch (Exception e) {
                System.err.println("Wrong Argument");
                System.exit(1);
            }
        }
        
        String filename;
        NodeInfo[] nodes = new NodeInfo[NUM_NODES];
        for (int i = 0; i <= 25; i++) {
            filename = inDir + queryid + i + ".txt";
            nodes[i] = new NodeInfo();
           
            try {
                ReadNode(filename, nodes[i]);
            }
            catch (Exception ex)
            {

            }
        }

        filename = inDir + "/out.txt";
        ReadOut(filename, nodes);
        
        for (int i = 0; i < NUM_NODES; i++) {
             System.out.println(i + " " + nodes[i].getSent() + " " 
                    + nodes[i].getRecv() + " "
                    + nodes[i].getFirstReceivedTime() + " "
                    + nodes[i].getLastReceivedTime() + " "
                    + nodes[i].getRedundant() + " "
                    + nodes[i].getMana() + " "
                     + nodes[i].getRouting() + " "
                     + nodes[i].getMgAddr() + " "
                     + nodes[i].getForward());
        }
        
        filename = outDir;
        WriteToFile(filename, nodes);
        if (outVol != null) {
            WriteVoltage(outVol, nodes);
        }
    }

    private static void ReadNode(String fn, NodeInfo node) {
        FileInputStream fis = null;
        BufferedReader reader = null;
        List<Integer> data = new ArrayList<Integer>();
        try {

            fis = new FileInputStream(fn);
            reader = new BufferedReader(new InputStreamReader(fis));

            String line = reader.readLine();
            int c = 0;
            long f = 0;
            long l = 0;
            int r = 0;
            int oldSeq = 0;
            int newSeq;
            while (line != null) {
                String[] list = line.split(" ");
                
                if (c == 0)
                {
                    f = Long.parseLong(list[2]);
                    oldSeq = Integer.parseInt(list[1]);
                    c++;
                }
                else
                {
                    newSeq = Integer.parseInt(list[1]);
                    if (newSeq <= oldSeq)
                    {
                        r++;
                    }
                    else
                    {
                        oldSeq = newSeq;
                        c++;
                    }
                }
                l = Long.parseLong(list[2]);
                data.add(Integer.parseInt(list[3]));
                line = reader.readLine();
            }

            node.setRecv(c);
            node.setFirstReceivedTime(f);
            node.setLastReceivedTime(l);
            node.setRedundant(r);
            node.setVolData(data);
            
        } catch (FileNotFoundException ex) {
            System.out.println("File not found " + fn);
        } catch (IOException ex) {
            System.out.println(ex.getMessage());

        } finally {
            try {
                reader.close();
                fis.close();
            } catch (IOException ex) {
                System.out.println(ex.getMessage());
            }
        }
    }
    
    private static void ReadOut(String fn, NodeInfo[] nodes)
    {
        FileInputStream fis = null;
        BufferedReader reader = null;
        try {

            fis = new FileInputStream(fn);
            reader = new BufferedReader(new InputStreamReader(fis));
            String line = reader.readLine();
           
            Pattern datePattern = Pattern.compile("^(\\d{2})-(\\w{3})-(\\d{4}) (([0-1]?[0-9])|(2[0-3])):[0-5][0-9]");
            while (line != null) {
                Matcher dateMatcher = datePattern.matcher(line);
                if (dateMatcher.find()) {
                    
                    line = reader.readLine();
                    continue;
                }
                String[] list = line.split(" ");
               
                int nid = Integer.parseInt(list[0]);
                try {
                    nodes[nid].setSent(Integer.parseInt(list[1]));
                    nodes[nid].setMana(Integer.parseInt(list[2]));
                    nodes[nid].setRouting(Integer.parseInt(list[3]));
                    nodes[nid].setMgAddr(Integer.parseInt(list[4]));
                    nodes[nid].setForward(Integer.parseInt(list[5]));
                } catch (Exception ex) {
                }
                line = reader.readLine();
            }
        }
        catch (FileNotFoundException ex) {
                System.out.println("File not found");
        }
        catch (IOException ex) {
                System.out.println(ex.getMessage());
        }

        finally {
            try {
                reader.close();
                fis.close();
            } catch (IOException ex) {
                System.out.println(ex.getMessage());
            }
        }
    }
      
    private static void WriteToFile(String fn, NodeInfo[] nodes)
    {
         try {
            FileWriter outFile = new FileWriter(fn, false);
            PrintWriter out = new PrintWriter(outFile);
            for (int i = 0; i < NUM_NODES; i++) {
                out.println(i + " " + nodes[i].getSent() + " " 
                    + nodes[i].getRecv() + " "
                    + nodes[i].getFirstReceivedTime() + " "
                    + nodes[i].getLastReceivedTime() + " "
                    + nodes[i].getRedundant() + " "
                    + nodes[i].getMana() + " "
                     + nodes[i].getRouting() + " "
                     + nodes[i].getMgAddr() + " "
                        + nodes[i].getForward());
            }
            out.close();
        } catch (IOException e) {
        }
    }
    
    private static void WriteVoltage(String fn, NodeInfo[] nodes)
    {
        String tmp = fn;
        for (int i = 0; i < NUM_NODES; i++) {
            fn = tmp + "_" + i + "_voltage";
            try {
                FileWriter outFile = new FileWriter(fn, true);
                PrintWriter out = new PrintWriter(outFile);
                Integer[] arr = nodes[i].getVolData().toArray(new Integer[nodes[i].getVolData().size()]);
                for (int j = 0; j < arr.length; j++)
                {
                    out.println(arr[j]);
                }
                
                out.close();
            } catch (Exception e) {
            }

        }
    }
    
    private static boolean IsExist(String dir)
    {
        File folderExisting;
        folderExisting = new File(dir);
        return folderExisting.exists();
    }
}
