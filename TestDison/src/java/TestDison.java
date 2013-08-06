/**
 *
 * @author Trang
 */

import net.tinyos.message.*;
import net.tinyos.util.*;
import java.io.*;
import java.util.Date;
import java.text.DateFormat;
import java.util.Iterator;
import java.util.Timer;
import java.util.TimerTask;

public class TestDison implements MessageListener {
    MoteIF gateway;
    MoteData data;
    Window ui;
    Date date;
    Timer timer;
    
    void run() {
        int mapPanelCounter = 0;
        
        data = new MoteData(this);
        ui = new Window(this, data);
        
	gateway = new MoteIF(PrintStreamMessenger.err);
	gateway.registerListener(new DisonTestMsg(), this);
        gateway.registerListener(new DisonLogMsg(), this);
        gateway.registerListener(new DisonTopoMsg(), this);
        ui.createGui();
        
        while(true) {
            try {
                Thread.sleep(Util.UPDATE_DIAGRAM_PERIOD);
            } catch (Exception e) { e.printStackTrace();}
            
            mapPanelCounter++;
            if (mapPanelCounter>=10) {		// 1 sec
		
		mapPanelCounter=0;
            }
	}
    }
    
    synchronized public void messageReceived(int dest_addr, Message msg) {
        if (msg instanceof DisonTestMsg) {
            DisonTestMsg dtmsg = (DisonTestMsg)msg;
            System.out.println(msg);
            ui.append("Received 1 msg: Node " + dtmsg.get_id());
            WriteToFile(dtmsg);
            Mote localMote;
            localMote = data.getMote(dtmsg.get_id());
            waitMutex();
            if (localMote == null)
            {
                date = new Date();
                data.addMote(new Mote(dtmsg.get_id(),
                        date.getTime()));
                localMote = data.getMote(dtmsg.get_id());
                if (localMote != null)
                {
                    localMote.update(dtmsg.get_count(), dtmsg.get_readings());
                    ui.updateDataTable(dtmsg.get_id(), true);
                }
            }
            else
            {
                localMote.setNoMsgs();
                localMote.setLastTimeSeen(date.getTime());
                localMote.update(dtmsg.get_count(), dtmsg.get_readings());
                ui.updateDataTable(dtmsg.get_id(), false);
            }
            data.releaseMutex();
            return;
        }
        if (msg instanceof DisonLogMsg) {
            DisonLogMsg dstat = (DisonLogMsg)msg;
            System.out.println(msg);
            ui.append("Received 1 log msg: Node " + dstat.get_id());
            WriteToFile("out.txt", dstat);
	}
        System.out.println(msg);
        if (msg instanceof DisonTopoMsg) {
            DisonTopoMsg dtopo = (DisonTopoMsg)msg;
            System.out.println(msg);
            ui.append("Received 1 topo msg: Node " + dtopo.get_id());
            WriteToFile(dtopo);
        }
    }
    
    public void sendQuery(int sensingType, int samplingPeriod, int queryPeriod)
    {
        short noParams = 3;
        int[] params;
        params = new int[Constants.MAX_PARAMS];
        params[0] = sensingType;
        params[1] = samplingPeriod;
        params[2] = queryPeriod;
        ui.append("Send a query [" + sensingType + " " + samplingPeriod + " " + 
                queryPeriod + "] to network");
        DisonRequestMsg msg = new DisonRequestMsg();
        msg.set_dstId(MoteIF.TOS_BCAST_ADDR);
        msg.set_type(Constants.QUERY_REQUEST);
        msg.set_noParams(noParams);
        msg.set_params(params);
        try {
            gateway.send(MoteIF.TOS_BCAST_ADDR, msg);
        } catch (IOException e) {
            ui.append("Cannot send message to mote " + e.toString());
        }
    }
    
    public void sendConfigRequest(int command, int value)
    {
        short noParams = 2;
        int[] params;
        params = new int[Constants.MAX_PARAMS];
        params[0] = command;
        params[1] = value;
        ui.append("Send a command to network");
        DisonRequestMsg msg = new DisonRequestMsg();
        msg.set_dstId(MoteIF.TOS_BCAST_ADDR);
        msg.set_type(Constants.COMMAND_REQUEST);
        msg.set_noParams(noParams);
        msg.set_params(params);
        try {
            gateway.send(MoteIF.TOS_BCAST_ADDR, msg);
        } catch (IOException e) {
            ui.append("Cannot send message to mote " + e.toString());
        }
    }
    
    public void setupAutoTest(int sensingType, int samplingPeriod, int queryPeriod, boolean useDison)
    {
        short noParams = 4;
        int[] params;
        params = new int[Constants.MAX_PARAMS];
        params[0] = sensingType;
        params[1] = samplingPeriod;
        params[2] = queryPeriod;
        params[3] = useDison ? 1 : 0;
        ui.append("Send a auto test command to network [" + sensingType + " " + samplingPeriod + " " + 
                queryPeriod + " " + useDison + "]");
        DisonRequestMsg msg = new DisonRequestMsg();
        msg.set_dstId(MoteIF.TOS_BCAST_ADDR);
        msg.set_type(Constants.AUTOTEST_REQUEST);
        msg.set_noParams(noParams);
        msg.set_params(params);
        timer = new Timer();  //At this line a new Thread will be created
        timer.schedule(new RepeatTest(this, msg), 0, queryPeriod*60*1000 + 2*Constants.AUTO_TEST_TIME); //delay in milliseconds
    }
    
    public void reSendQuery(DisonRequestMsg msg)
    {
         try {
            gateway.send(MoteIF.TOS_BCAST_ADDR, msg);
            WriteCurrentTimeToFile("out.txt");
        } catch (IOException e) {
            ui.append("Cannot send message to mote " + e.toString());
        }
    }
           
    public static void main(String[] args) {
        TestDison me = new TestDison();
        me.run();
    }
    
    public void waitMutex() {
        try {
            while (!data.getMutex()) {
                Thread.sleep(Util.MUTEX_WAIT_TIME_MS);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
    
    public void clear()
    {
        data = new MoteData(this);
    }
    
    public void WriteToFile(String filename, DisonLogMsg msg) {
        try {
            FileWriter outFile = new FileWriter(filename, true);
            PrintWriter out = new PrintWriter(outFile);
            date = new Date();
            out.println(msg.get_id() + " " + 
                    msg.get_app_sent_pkts() + " " +
                    msg.get_mana_pkts() + " " +
                    msg.get_routing_pkts() + " " +
                    msg.get_mgAddr() + " " + 
                    msg.get_forwarding_pkts() + " " + date.getTime() + " " + 
                    DateFormat.getDateTimeInstance().format(date) + " " +
                    msg.get_app_sent_bytes() + " " +
                    msg.get_mana_bytes() + " " + 
                    msg.get_routing_bytes() + " " +
                    msg.get_forwarding_bytes());
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    public void WriteToFile(DisonTestMsg msg)
    {
         try {
            String fn;
            fn = msg.get_queryID() + "_" + msg.get_id() + ".txt";
            FileWriter outFile = new FileWriter(fn, true);
            PrintWriter out = new PrintWriter(outFile);
            date = new Date();
            out.println(msg.get_id() + " " + msg.get_count() + " " + date.getTime()
                    + " " + msg.get_readings()[0]);
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    public void WriteToFile(DisonTopoMsg msg)
    {
        try {
            String fn;
            fn = msg.get_id() + "_topo.txt";
            FileWriter outFile = new FileWriter(fn, true);
            PrintWriter out = new PrintWriter(outFile);
            for (int i = 0; i < msg.get_noNodes(); i++)
            {
                out.println(msg.get_nodeList()[i]);
            }
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    public void ExportToFile(String filename) {
        try {
            FileWriter outFile = new FileWriter(filename, true);
            PrintWriter out = new PrintWriter(outFile);
            date = new Date();
            int i;
            long n;
            Mote tmp;
            if (data == null)
                  return;
            for (i = 0; i <= 25; i++) {
                tmp = data.getMote(i);
                if (tmp != null) {
                    n = tmp.getNoMsgs();
                }
                else {
                    n = 0;
                }
                out.println(i + " "
                    + n + " "
                    + DateFormat.getDateTimeInstance().format(date));
               
            }
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    public void WriteCurrentTimeToFile(String filename) {
         try {
            FileWriter outFile = new FileWriter(filename, true);
            PrintWriter out = new PrintWriter(outFile);
            date = new Date();
            out.println(DateFormat.getDateTimeInstance().format(date));
            out.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    class RepeatTest extends TimerTask
    {
        TestDison parent;
        DisonRequestMsg msg;
        int round;
        
        @Override
        public void run() {
            System.out.println("Timer is fired " + round);
            if (round < 1)
            {
                parent.reSendQuery(msg);
                System.out.println("Resend query");
            }
            else
            {
                timer.cancel();
                System.out.println("Cancel timer");
                sendConfigRequest(Constants.CMD_RESET_NETWORK, 1);
                //sendConfigRequest(Constants.CMD_GET_TOPO, 1);
            }
            round++;
            
        }

        public RepeatTest(TestDison parent, DisonRequestMsg msg) {
            this.parent = parent;
            this.msg = msg;
            round = 0;
        }
    }
}

