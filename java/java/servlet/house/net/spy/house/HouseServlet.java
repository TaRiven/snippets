/*
 * Copyright (c) 1999 Dustin Sallings
 *
 * $Id: HouseServlet.java,v 1.1 2001/02/23 07:09:31 dustin Exp $
 */

package net.spy.house;

import java.io.*;
import java.util.*;
import java.net.*;
import sun.misc.*;

import javax.servlet.*;
import javax.servlet.http.*;

import net.spy.*;
import net.spy.net.*;
import net.spy.temperature.*;

import java.awt.*;
import java.awt.image.*;

import com.mongus.servlet.GifServlet;

// The class
public class HouseServlet extends GifServlet implements ImageObserver
{
	// Colors we'll be using
	Color white=null;
	Color red=null;
	Color blue=null;
	Color black=null;

	// The base house image.
	Image baseImage=null;

	// The once only init thingy.
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		getBaseImage();
		white=new Color(255, 255, 255);
		red=new Color(255, 0, 0);
		blue=new Color(0, 0, 255);
		black=new Color(0, 0, 0);
	}

	// Do a GET request
	public void doGet (
		HttpServletRequest request, HttpServletResponse response
	) throws ServletException, IOException {
		try {
			writeGif(response, getHouseImage());
		} catch(Exception e) {
			e.printStackTrace();
			throw new ServletException("Error getting image:  " + e);
		}
	}

	// Graphical representation of the image.
	protected Image getHouseImage() throws Exception {
		Image img=createImage(307, 223);
		Graphics g=img.getGraphics();
		g.drawImage(baseImage, 0, 0, this);
		SpyTemp spytemp=new SpyTemp();

		// The description of what we're drawing.
		SpyConfig conf=new SpyConfig(
			"/afs/spy.net/misc/web/etc/house.conf"
			);

		// Find all the things we need to colorize
		String things[]=SpyUtil.split(" ", conf.get("colorize", ""));
		for(int i=0; i<things.length; i++) {
			int x, y, w, h;

			String rstring=null;

			x=conf.getInt(things[i] + ".rect.x", 0);
			y=conf.getInt(things[i] + ".rect.y", 0);
			w=conf.getInt(things[i] + ".rect.w", 0);
			h=conf.getInt(things[i] + ".rect.h", 0);
			// Default color is white
			g.setColor(white);

			try {
				double reading=spytemp.getTemp(things[i]);
				rstring="" + reading;

				// Set the color based on the temperature reading.
				if(reading< conf.getInt(things[i] + ".min", 0)) {
					g.setColor(blue);
				} else if(reading> conf.getInt(things[i] + ".max", 0)) {
					g.setColor(red);
				}

				// Stick the color all up in there.
				g.fillRect(x, y, w, h);
			} catch(Exception e) {
				rstring="??.??";
			}
			// Put the reading in there.
			g.setColor(black);
			g.drawString(rstring, (x+(w/2)-18), (y+(h/2)+4));
		}

		return(img);
	}

	protected void getBaseImage() {
		try {
			if(baseImage==null) {
				String url="http://bleu.west.spy.net/~dustin/images/house.gif";
				baseImage=Toolkit.getDefaultToolkit().getImage(new URL(url));
			}
		} catch(Exception e) {
			System.err.println("Error fetching base image:  " +e);
			e.printStackTrace();
		}
	}

	// When imageUpdate is called...yeah, this sucks.
	public boolean imageUpdate(Image img, int infoflags,
		int x, int y, int width, int height) {
		return(true);
	}
}
