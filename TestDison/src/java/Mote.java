
import java.util.Arrays;
import java.awt.Color;

/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

/**
 *
 * @author Trang
 */
public class Mote {
    private int moteId;
    private int x, y;
    private int order;
    private long lastTimeSeen; 	// last time a message was emitted by the mote
    private long noMsgs;
    private Color color;
    
    /* Data is hold in an array whose size is a multiple of INCREMENT, and
       INCREMENT itself must be a multiple of Constant.NREADINGS. This
       simplifies handling the extension and clipping of old data
       (see setEnd) */
    final static int INCREMENT = 100 * Constants.NREADINGS;
    final static int MAX_SIZE = 100 * INCREMENT; // Must be multiple of INCREMENT
    
    /* Data received from the mote. data[0] is the dataStart'th sample
       Indexes 0 through dataEnd - dataStart - 1 hold data.
       Samples are 16-bit unsigned numbers, -1 indicates missing data. */
    int[] data;
    int dataStart, dataEnd;
    
    public Mote(int moteId, long lastTimeSeen) {
        this.moteId = moteId;
        this.lastTimeSeen = lastTimeSeen;
        this.x = (int)(Math.random() * Util.X_MAX);
        this.y = (int)(Math.random() * Util.Y_MAX);
        noMsgs = 1;
    }

    public boolean isGateway() {
	if(moteId == 0)
        {
            return true;
        }
	else
        {
            return false;
        }
    }
    
    public int getMoteId() {
        return moteId;
    }

    public int getX() {
        return x;
    }

    public int getY() {
        return y;
    }

    public void setX(int x) {
        this.x = x;
    }

    public void setY(int y) {
        this.y = y;
    }

    public long getLastTimeSeen() {
        return lastTimeSeen;
    }

    public void setLastTimeSeen(long lastTimeSeen) {
        this.lastTimeSeen = lastTimeSeen;
    }

    public int getOrder() {
        return order;
    }

    public void setOrder(int order) {
        this.order = order;
    }

    public long getNoMsgs() {
        return noMsgs;
    }

    public void setNoMsgs() {
        this.noMsgs++;
    }

    public Color getColor() {
        return color;
    }

    public void setColor(Color color) {
        this.color = color;
    }
    
    
    
    /* Update data to hold received samples newDataIndex .. newEnd.
     If we receive data with a lower index, we discard newer data
     (we assume the mote rebooted). */
    private void setEnd(int newDataIndex, int newEnd) {
        if (newDataIndex < dataStart || data == null) {
            /* New data is before the start of what we have. Just throw it
             all away and start again */
            dataStart = newDataIndex;
            data = new int[INCREMENT];
        }
        if (newEnd > dataStart + data.length) {
            /* Try extending first */
            if (data.length < MAX_SIZE) {
                int newLength = (newEnd - dataStart + INCREMENT - 1) / INCREMENT * INCREMENT;
                if (newLength >= MAX_SIZE) {
                    newLength = MAX_SIZE;
                }

                int[] newData = new int[newLength];
                System.arraycopy(data, 0, newData, 0, data.length);
                data = newData;

            }
            if (newEnd > dataStart + data.length) {
                /* Still doesn't fit. Squish.
                 We assume INCREMENT >= (newEnd - newDataIndex), and ensure
                 that dataStart + data.length - INCREMENT = newDataIndex */
                int newStart = newDataIndex + INCREMENT - data.length;

                if (dataStart + data.length > newStart) {
                    System.arraycopy(data, newStart - dataStart, data, 0,
                            data.length - (newStart - dataStart));
                }
                dataStart = newStart;
            }
        }
        /* Mark any missing data as invalid */
        for (int i = dataEnd < dataStart ? dataStart : dataEnd;
                i < newDataIndex; i++) {
            data[i - dataStart] = -1;
        }

        /* If we receive a count less than the old count, we assume the old
         data is invalid */
        dataEnd = newEnd;

    }

    /* Data received containing NREADINGS samples from messageId * NREADINGS 
       onwards */
    public void update(int messageId, int[] readings)
    {
        int start = messageId * Constants.NREADINGS;
        setEnd(start, start + Constants.NREADINGS);
        System.arraycopy(readings, 0, data, start - dataStart, readings.length);
        System.out.println(Arrays.toString(data));
    }
    
    public int getLastData()
    {
        return data[dataEnd - dataStart - 1];
    }
    
    public int getData(int x)
    {
        if (x < dataStart || x >= dataEnd) {
            return -1;
        }
        else {
            return data[x - dataStart];
        }
    }
    
    /* Return number of last known sample */
    public int maxX() {
        return dataEnd - 1;
    }
}
