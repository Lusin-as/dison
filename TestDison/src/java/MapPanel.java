
import java.awt.Color;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.event.MouseEvent;
import java.awt.event.MouseListener;
import java.awt.event.MouseMotionListener;
import java.awt.geom.Rectangle2D;
import javax.swing.JPanel;

/**
 *
 * @author Trang
 */
public class MapPanel extends JPanel implements MouseListener, MouseMotionListener {
    private MoteData data;

    public MapPanel(MoteData data) {
        this.data = data;
    }

    public void paint(Graphics g) {
        Graphics2D g2 = (Graphics2D) g;
        Dimension d = getSize();
        g2.setPaint(Color.black);
        g2.fill(new Rectangle2D.Double(0, 0, d.width, d.height));
        g2.setPaint(Color.white);
        g2.fill(new Rectangle2D.Double(Util.MOTE_RADIUS, Util.MOTE_RADIUS, d.width-2*Util.MOTE_RADIUS, d.height-2*Util.MOTE_RADIUS));
    }
    
    public void mouseExited(MouseEvent e) {}
    
    public void mouseEntered(MouseEvent e) {}

    @Override
    public void mouseClicked(MouseEvent e) {
        
    }

    @Override
    public void mousePressed(MouseEvent e) {
       
    }

    @Override
    public void mouseReleased(MouseEvent e) {
        
    }

    @Override
    public void mouseDragged(MouseEvent e) {
        
    }

    @Override
    public void mouseMoved(MouseEvent e) {
        
    }
    
    
}
