/*
 * Copyright (c) 1997  Dustin Sallings
 *
 * $Id: phonebook.c,v 1.1 1997/06/16 13:46:05 dustin Exp $
 */

#include <stdio.h>
#include <X11/Intrinsic.h>
#include <Xm/Xm.h>
#include <Xm/MainW.h>
#include <Xm/CascadeB.h>
#include <Xm/Frame.h>
#include <Xm/RowColumn.h>
#include <Xm/PushB.h>
#include <Xm/PushBG.h>
#include <Xm/TextF.h>
#include <Xm/Text.h>
#include <Xm/Form.h>
#include <Xm/LabelG.h>

#include "phonebook.h"
#include "fields.h"

progdata globl;

extern char **dbrnames, **dbfnames;

Widget CreateMenus(Widget main_window, infotype *info)
{
    Widget menu_bar, menu_pane, menu_pane2, button, cascade;
    Arg args[MAX_ARGS];
    int n;

    /* create a menu bar */

    n=0;
    menu_bar = XmCreateMenuBar(main_window, "menu_bar", args, n);
    XtManageChild(menu_bar);

    n=0;
    menu_pane=XmCreatePulldownMenu(menu_bar, "menu_pane1", args, n);

    /* buttons for first menu thing */

    n=0;
    button = XmCreatePushButton(menu_pane, "Show Fields", args, n);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, ShowFields, NULL);

    n=0;
    button = XmCreatePushButton(menu_pane, "Quit", args, n);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, Quit, NULL);

    /* first menu thing */

    n=0;
    XtSetArg(args[n], XmNsubMenuId, menu_pane); n++;
    cascade=XmCreateCascadeButton(menu_bar, "File", args, n);
    XtManageChild(cascade);

    /* new menu pane */

    n = 0;
    menu_pane2 = XmCreatePulldownMenu(menu_bar, "menu_pane2", args, n);

    n = 0;
    button = XmCreatePushButton(menu_pane2, "Help", args, n);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, Help, NULL);

    /* button under new menu */

    n = 0;
    button = XmCreatePushButton(menu_pane2, "About", args, n);
    XtManageChild(button);
    XtAddCallback(button, XmNactivateCallback, About, NULL);

    /* new menu */

    n = 0;
    XtSetArg(args[n], XmNsubMenuId, menu_pane2);
    n++;
    cascade = XmCreateCascadeButton(menu_bar, "Help", args, n);
    XtManageChild(cascade);

    n = 0;
    XtSetArg(args[n], XmNmenuHelpWidget, cascade); n++;
    XtSetValues(menu_bar, args, n);

    return(menu_bar);
}

Widget CreateInputs(Widget form, infotype *info)
{
    Widget rowcolumn, button, frame;
    XmString label_string;
    Arg args[MAX_ARGS];
    int n, i;

    for(i=0; i<NFIELDS; i++)
    {

        n=0;
        XtSetArg(args[n], XmNpacking, XmPACK_COLUMN); n++;
        XtSetArg(args[n], XmNorientation, XmHORIZONTAL); n++;
        rowcolumn=XmCreateRowColumn(form, "inputs", args, n);
        XtManageChild(rowcolumn);

        label_string = XmStringCreateLocalized(dbrnames[i]);

        n=0;
        XtSetArg(args[n], XmNlabelString, label_string); n++;
	XtSetArg(args[n], XmCAttachment, XmNleftAttachment);
        XtManageChild(XmCreateLabelGadget(rowcolumn, dbfnames[i], args, n));

        XmStringFree(label_string);

        n=0;
        XtSetArg(args[n], XmNmaxLength, 32); n++;
        XtSetArg(args[n], XmNcolumns, 32); n++;
	XtSetArg(args[n], XmCAttachment, XmNrightAttachment);
        info->data[i]=XmCreateTextField(rowcolumn, dbfnames[i], args, n);
        XtManageChild(info->data[i]);

    }

    n=0;
    frame=XmCreateFrame(form, "buttons", args, n);
    XtManageChild(frame);

    n=0;
    XtSetArg(args[n], XmNpacking, XmPACK_COLUMN); n++;
    XtSetArg(args[n], XmNorientation, XmHORIZONTAL); n++;
    rowcolumn=XmCreateRowColumn(frame, "inputs", args, n);
    XtManageChild(rowcolumn);

    label_string = XmStringCreateLocalized("Quit");
    n=0;
    XtSetArg(args[n], XmNlabelString, label_string); n++;
    button=XmCreatePushButtonGadget(rowcolumn, "button", args, n);
    XtAddCallback(button, XmNactivateCallback, Quit, NULL);
    XtManageChild(button);
    XmStringFree(label_string);

    label_string = XmStringCreateLocalized("Find");
    n=0;
    XtSetArg(args[n], XmNlabelString, label_string); n++;
    button=XmCreatePushButtonGadget(rowcolumn, "button", args, n);
    XtAddCallback(button, XmNactivateCallback, Find, NULL);
    XtManageChild(button);
    XmStringFree(label_string);

    label_string = XmStringCreateLocalized("Store");
    n=0;
    XtSetArg(args[n], XmNlabelString, label_string); n++;
    button=XmCreatePushButtonGadget(rowcolumn, "button", args, n);
    XtAddCallback(button, XmNactivateCallback, Store, (XtPointer) info);
    XtManageChild(button);
    XmStringFree(label_string);

}

Widget CreateApplication(Widget parent, infotype *info)
{
    Widget main_window, row_column, frame, form, text_thing;
    Arg args[MAX_ARGS];
    int n;

    /* create main window */

    n=0;
    main_window=XmCreateMainWindow(parent, "main_window", args, n);
    XtManageChild(main_window);

    globl.parent=main_window;

    /* Create the menu bar */
    CreateMenus(main_window, info);

    /* Now here's a frame to hold the rest of the stuff */
    n = 0;
    frame = XmCreateFrame(main_window, "frame", args, n);
    XtManageChild(frame);

    n = 0;
    XtSetArg(args[n], XmNnumColumns, 2); n++;
    XtSetArg(args[n], XmNpacking, XmPACK_TIGHT); n++;
    form = XmCreateRowColumn(frame, "form", args, n);
    XtManageChild(form);

/*
    n=0;
    form = XmCreateForm(frame, "form", args, n);
    XtManageChild(form);
*/

    /* Input dialogs */
    CreateInputs(form, info);
}

int main(int argc, char **argv)
{
    Widget app_shell, main_window;
    XtAppContext app_context;
    infotype info;

    initfields();

    app_shell = XtAppInitialize(&app_context, "Phonebook", NULL, 0, &argc,
	  argv, NULL, NULL, 0);

    main_window=CreateApplication(app_shell, &info);
    XtRealizeWidget(app_shell);
    XtAppMainLoop(app_context);

    exit(0);
}
