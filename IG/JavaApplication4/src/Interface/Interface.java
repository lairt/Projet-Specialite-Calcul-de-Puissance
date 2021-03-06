/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package Interface;

import java.awt.Dimension;
import org.rosuda.JRI.RVector;
import org.rosuda.JRI.Rengine;
import org.rosuda.REngine.REngine;

/**
 *
 * @author Lair Thomas, Bonjean Grégoire & Crépin Baptiste
 */
public class Interface {

    //        eng.eval("library(regression)");
//        eng.eval("b=regression_blind(2, 20)");
//        RVector fat = eng.eval("b").asVector();
//        double[] db = fat.at(0).asDoubleArray();
//        for (double d : db) {
//            System.out.println(d);
//        }
    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        final Rengine eng = new Rengine(new String[]{"--no-save"}, false, null);
        if (!eng.waitForR()) {
            System.out.println("Cannot load R");
            System.exit(1);
        }
        Fenetre fen = new FenetreOuverture("Menu Principal",
                new Dimension(1100, 400), null, null, null, null, true, eng);
    }
}
