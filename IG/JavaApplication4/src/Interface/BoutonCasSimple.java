/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package Interface;

import java.awt.Dimension;
import java.awt.Image;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.io.IOException;
import javax.imageio.ImageIO;
import javax.swing.ImageIcon;
import javax.swing.JButton;
import org.rosuda.JRI.Rengine;
import org.rosuda.REngine.REngine;

/**
 *
 * @author lairt
 */
public class BoutonCasSimple extends JButton {

    public BoutonCasSimple(final Fenetre fen_act,
            Boolean enabled,
            final Rengine eng) {
        super();

        try {
            Image img = ImageIO.read(getClass().getResource("loi_n.png"));
            setIcon(new ImageIcon(img));
        } catch (IOException e) {

        }

        setEnabled(enabled);

        this.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent event) {
                fen_act.setVisible(false);
                FenetreCas new_fen = new FenetreCas("Cas Simple",
                        new Dimension(1100, 650),
                        fen_act,
                        null,
                        fen_act.home,
                        null,
                        "Simple",
                        eng);
                new_fen.ret.setEnabled(true);
                new_fen.next.setEnabled(false);
            }
        }
        );
    }
}
