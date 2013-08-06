
import javax.swing.table.AbstractTableModel;

/**
 *
 * @author Trang
 */
public class MoteDataModel extends AbstractTableModel {
    MoteData data;

    public MoteDataModel(MoteData data) {
        this.data = data;
    }

    @Override
    public String getColumnName(int column) {
        switch (column)
        {
            case 0:
                return "Mote";
            case 1:
                return "Count";
            case 2:
                return "Temperature";
            case 3:
                return "Humidity";
            case 4:
                return "Light";
            case 5:
                return "Color";
            default:
                return "";
        }
    }
  
    @Override
    public Class getColumnClass(int col) {
        return getValueAt(0, col).getClass();
    }
    
    @Override
    public int getRowCount() {
        return data.getNoMotes();
    }

    @Override
    public int getColumnCount() {
       return 6;
    }

    @Override
    public Object getValueAt(int rowIndex, int columnIndex) {
        if (rowIndex > data.getNoMotes())
            return "";
        
        Mote localMote;
        localMote = data.getMoteByOrder(rowIndex);
        if (localMote == null)
            return "";
        switch (columnIndex)
        {
            case 0:
                return localMote.getMoteId();
            case 1:
                return localMote.getNoMsgs();
            case 2:
                return localMote.getLastData();
            case 5:
                return localMote.getColor();
            default:
                return "";
        }
    }
    
    public void clear() {
        fireTableDataChanged();
    }
    
    public synchronized void update(int moteId)
    {
        Mote m = data.getMote(moteId);
        if (m != null)
        {
            setValueAt(m.getNoMsgs(), m.getOrder(), 1);
            setValueAt(m.getLastData(), m.getOrder(), 2);
        }
    }
    
    public synchronized void add(int moteId) {
        Mote m;
        m = data.getMote(moteId);
        if (m != null)
        {
            fireTableRowsInserted(m.getOrder(), m.getOrder());
            setValueAt(m.getNoMsgs(), m.getOrder(), 1); //value, row, col
        }
    }
    
    @Override
    public synchronized void setValueAt(Object value, int row, int col)
    {
        fireTableCellUpdated(row, col);
    }

}


