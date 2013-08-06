/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Trang
 */

import java.awt.Color;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.*;

public class MoteData {
    private TestDison parent;
    private ArrayList moteNetwork;
    
    private int maxID;
    private int noMotes;
    private boolean mutexFree;

    MoteData(TestDison parent) {
        this.parent = parent;
        moteNetwork = new ArrayList();
        noMotes = 0;
        mutexFree = true;
    }
    
    public synchronized void addMote(Mote m)
    {
        if (moteNetwork.contains(m)) {
            System.out.println("[addMote] mote " + m.toString() + " ever in the DB");
            return;
        }
        m.setOrder(moteNetwork.size());
        moteNetwork.ensureCapacity(moteNetwork.size()+1);
        
        Random randomGenerator = new Random();
        int red = randomGenerator.nextInt(255);
        int green = randomGenerator.nextInt(255);
        int blue = randomGenerator.nextInt(255);

        Color randomColour = new Color(red, green, blue);
        m.setColor(randomColour);
        moteNetwork.add(m);
        noMotes++;
        System.out.println("Added mote " + m.getMoteId());
        int id = m.getMoteId();
        if(id > maxID){
            maxID=id;
        }
    }
    
    public synchronized void deleteMote(Mote m) {
        if(moteNetwork.contains(m)) {
            moteNetwork.remove(m);
            moteNetwork.trimToSize();
            noMotes--;
        } else
        {
           System.out.println("[deleteMote] Mote to delete not found");
	}
    }
    
    public synchronized Mote getMote(int moteId) {
        Mote tmp;
        for (Iterator it=moteNetwork.iterator(); it.hasNext(); ) {
            tmp = (Mote)it.next();
            if(tmp.getMoteId() == moteId)
                return tmp;
	}
	return null;
    }
    
    public synchronized Mote getMoteByOrder(int order) {
        Mote tmp;
        for (Iterator it = moteNetwork.iterator(); it.hasNext();) {
            tmp = (Mote) it.next();
            if (tmp.getOrder() == order) {
                return tmp;
            }
        }
        return null;
    }

    public int getNoMotes() {
        return noMotes;
    }
    
    public void releaseMutex() {
        mutexFree = true;
    }

    public boolean getMutex() {
        if (mutexFree) {
            mutexFree = false;
            return true;
        } else {
            return false;
        }
    }
    
    /* Return value of sample x for mote nodeId, or -1 for missing data */
    public int getData(int moteId, int x) {
        Mote localMote;
        localMote = getMote(moteId);
        return localMote.getData(x);
    }
 
    /* Return number of last known sample on mote nodeId. Returns 0 for
     unknown motes. */
    public int maxX(int moteId) {
        Mote localMote = getMote(moteId);
        if (localMote == null) {
            return 0;
        }
        return localMote.maxX();
    }

    /* Return number of largest known sample on all motes (0 if there are no
     motes) */
    public int maxX() {
        int max = 0;
        Mote tmp;
        for (Iterator it = moteNetwork.iterator(); it.hasNext();) {
            tmp = (Mote) it.next();
            int nmax = tmp.maxX();
            if (tmp.maxX() > max) {
                max = nmax;
            }
        }
        return max;
    }
}