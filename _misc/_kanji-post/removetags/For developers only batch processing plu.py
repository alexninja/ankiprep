#!/usr/bin/env python
# -*- coding: utf-8 -*-

#
# This plugin is for developers who need some help to get started with a batch processing
# plugin in Anki and _not_ for users.
#
# Experienced users who know some Python may find this useful to write some custom batch
# processing code. This example hooks into the action menu of the card list browser and 
# performs an action on each selected fact. The plugin as is is doing nothing, you have 
# to fill it with life to do something useful. 
#
# Be aware of what you do and what this code is doing before blindly using it.
#

from ankiqt import mw
from ankiqt.ui import utils
from anki.hooks import addHook
from PyQt4 import QtGui, QtCore

########################################################################################################

class BatchProcessor:
    def __init__(self, mw):
        mw.registerPlugin("batch_processor", 0)
        addHook('editor.setupMenus', self.setupMenus)

    def setupMenus(self, cardList):
        self.batchAction = QtGui.QAction("Batch Processor: perform batch action", mw)
        self.batchAction.setEnabled(True)
        self.cardList = cardList
        cardList.dialog.menuActions.addAction(self.batchAction)
        mw.connect(self.batchAction, QtCore.SIGNAL("triggered()"), self.batchProcessor)

    def collectFacts(self):
        selectedRows = self.cardList.dialog.tableView.selectionModel().selectedRows()
        model = self.cardList.model

        # Collect the facts from the current card selection.
        # Actually, there might be a simpler way to get the facts, it is just the way
        # I found first without looking too much.
        facts = set();
        for i in selectedRows:
            currentCard = model.getCard(i)
            currentFact = currentCard.fact
            facts.add(currentFact)

        return facts

    def batchProcessor(self):
        facts = self.collectFacts()
# The snippet below which is commented out is doing the actual batch processing.
# There is no need to perform SQL query or anything similar. Rather, read the fields
# from the fact object by accessing the model field names as index and write the values
# back to the fact as you want it. The results will be stored in the Anki database 
# automatically.
#
        for fact in facts:
#            field1 = fact["field1"]
#            fact["field2"] = process(field1)
#            fact["tags"] = u"huhulol"
#            QtGui.QMessageBox.information(None, 'LOL', str(dir(fact)))
#            QtGui.QMessageBox.information(None, 'LOL', str(type(fact.tags)))
            fact.tags = u"DELETEME"


        self.cardList.updateAfterCardChange()

########################################################################################################
        
if __name__ != "__main__":
    # Save a reference to the toolkit onto the mw, preventing garbage collection of PyQT objects
    mw.batchProcessor = BatchProcessor(mw)
else:
    print "This is a plugin for the Anki Spaced Repition learning system and cannot be run directly."
    print "Please download Anki from <http://ichi2.net/anki/>"
