/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package Interface;

import java.awt.Dimension;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.JButton;
import org.rosuda.JRI.Rengine;
import org.rosuda.REngine.REngine;

/**
 *
 * @author lairt
 */
public class BoutonPuissance extends JButton {

    public BoutonPuissance(final Fenetre fen_act,
            final Rengine eng) {
        super("Calcul de Puissance");

        this.addActionListener(new ActionListener() {
            public void actionPerformed(ActionEvent event) {
                fen_act.setVisible(false);
                FenetreCas new_fen = new FenetreCas("Cas Réel",
                        new Dimension(1100, 650),
                        fen_act,
                        null,
                        fen_act.home,
                        null,
                        "Réel",
                        eng);
                new_fen.ret.setEnabled(true);
                new_fen.next.setEnabled(false);
            }
        }
        );
    }
}
