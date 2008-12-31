#!/usr/bin/env jython

import java
import javax

class Messaging:

    def __init__(self, queueName):
        ht=java.util.Hashtable()

        ht['java.naming.factory.initial']='org.jnp.interfaces.NamingContextFactory'
        # ht['java.naming.provider.url']='jnp/localhost:1099'
        ht['java.naming.provider.url']='jnp://lamer.dhcp.2wire.com:1099'
        ht['java.naming.factory.url.pkgs']='org.jboss.namingrg.jnp.interfaces'

        ic=javax.naming.InitialContext(ht)
        qcf=ic.lookup("ConnectionFactory")
        conn=qcf.createQueueConnection()
        self.queue=ic.lookup(queueName)
        self.session=conn.createQueueSession(
            0, javax.jms.QueueSession.AUTO_ACKNOWLEDGE)
        conn.start()

    def sendMessage(self, msgtext):
        tm=self.session.createTextMessage(msgtext)
        send=self.session.createSender(self.queue)
        send.send(tm)
        send.close()

    def queueSequence(self, n):
        for x in range(n):
            self.sendMessage("Test #%d" % x)

def getMessaging():
    return Messaging("queue/testQueue")
