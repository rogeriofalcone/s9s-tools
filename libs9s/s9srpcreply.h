/*
 * Severalnines Tools
 * Copyright (C) 2016  Severalnines AB
 *
 * This file is part of s9s-tools.
 *
 * s9s-tools is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 2 of the License, or
 * (at your option) any later version.
 *
 * S9sTools is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with S9sTools. If not, see <http://www.gnu.org/licenses/>.
 */
#pragma once

#include "S9sVariantMap"
#include "S9sFormat"

class S9sNode;
class S9sCluster;
class S9sFormat;
class S9sCmonGraph;
class S9sUser;
class S9sServer;

class S9sRpcReply : public S9sVariantMap
{
    public:
        enum ErrorCode
        {
            Ok                = 0,
            InvalidRequest    = 100,
            ObjectNotFound    = 101,
            TryAgain          = 102,
            ClusterNotFound   = 103,
            UnknownError      = 104,
            AccessDenied      = 105,
            AuthRequired      = 106
        };

        bool isOk() const;
        S9sRpcReply::ErrorCode requestStatus() const;
        bool isAuthRequired() const;
        S9sString errorString() const;
        S9sString uuid() const;


        int jobId() const;
        S9sString jobTitle() const;
        bool isJobFailed() const;

        // Methods handling clusters.
        S9sCluster cluster(const S9sString &clusterName);
        S9sVariantList clusters();

        S9sString clusterName(const int clusterId);
        S9sString clusterStatusText(const int clusterId);

        bool progressLine(S9sString &retval, bool syntaxHighlight);

        void printMessages(const S9sString &defaultMessage);
        void printCheckHostsReply();
        void printJobStarted();
        void printJobLog();
        void printCat();
        void printAcl();
        void printClusterList();
        void printConfigList();
        void printLogList();
        void printNodeList();
        void printJobList();
        void printBackupList();
        void printKeys();
        
        // Methods handling users.
        void printUserList();
        void printUserListStat();
        void printUserListStat(const S9sUser &user);

        S9sUser getUser(const S9sString &userName);

        void printGroupList();
        void printAccountList();
        void printDatabaseList();
        void printMaintenanceList();
        void printMetaTypeList();
        void printMetaTypePropertyList();
        void printPing();
        void printServers();
        void printServersLong();
        void printServersBrief();

        void printProcessors(S9sString indent = S9sString());
        void printDisks(S9sString indent = S9sString());
        void printPartitions(S9sString indent = S9sString());
        void printNics(S9sString indent = S9sString());
        void printMemoryBanks(S9sString indent = S9sString());
        
        // Handling containers.
        S9sContainer container(
                const S9sString &serverName, 
                const S9sString &containerName);

        void printContainers();
        void printContainersLong();
        void printContainersCompact(const S9sVariantList &containers);
        void printContainerListStat();
        void printContainerListStat(S9sContainer &container);

        void printProcessList();
        void printProcessListBrief(const int maxLines = -1);
        void printCpuStat();
        void printCpuStatLine1();
        void printMemoryStatLine1();
        void printMemoryStatLine2();

        void printScriptOutput();
        void printScriptBacktrace();
        void printScriptOutputBrief();

        void printScriptTree();
        void printScriptTreeBrief();
        
        void printObjectTree();
        void printObjectTreeList();
        void printObjectTreeBrief();
        void printObjectTreeLong();
        
        void saveConfig(S9sString outputDir);


        void printScriptTreeBrief(
                S9sVariantMap        entry,
                int                  recursionLevel,
                S9sString            indentString,
                bool                 isLast);

        void printObjectTreeBrief(
                S9sVariantMap        entry,
                int                  recursionLevel,
                S9sString            indentString,
                bool                 isLast);
        
        void printObjectTreeLong(
                S9sVariantMap        entry,
                int                  recursionLevel,
                S9sString            indentString,
                bool                 isLast);

        static S9sString progressBar(double percent, bool syntaxHighlight);
        static S9sString progressBar(bool syntaxHighlight);

        static bool useSyntaxHighLight() ;

        static const char *hostStateColorBegin(const S9sString state);
        static const char *hostStateColorEnd();

        static const char *clusterStateColorBegin(S9sString state);
        static const char *clusterStateColorEnd();
        
        static const char *containerColorBegin();
        static const char *containerColorEnd();
        
        static const char *ipColorBegin();
        static const char *ipColorEnd();
        
        static const char *userColorBegin();
        static const char *userColorEnd();
        
        static const char *serverColorBegin();
        static const char *serverColorEnd();
        
        static const char *groupColorBegin(const S9sString &groupName = "");
        static const char *groupColorEnd();
        
        static const char *fileColorBegin(const S9sString &fileName);
        static const char *fileColorEnd();
       
        bool printGraph();
        bool createGraph(
                S9sVector<S9sCmonGraph *> &graphs, 
                S9sNode                   &host);

        bool createGraph(
                S9sVector<S9sCmonGraph *> &graphs, 
                S9sNode                   &host,
                const S9sString           &filterName,
                const S9sVariant          &filterValue);
        
        void printReport();


    protected:
        S9sVariantMap clusterMap(const int clusterId);
        
    private:
        void printServerStat(S9sServer server);
        void printServersStat();

        void printJobLogBrief();
        void printJobLogLong();
        
        void printLogBrief();
        void printLogLong();

        void printConfigBrief();
        
        void printConfigBrief(
                S9sVariantMap   map, 
                S9sFormat      &sectionFormat,
                S9sFormat      &nameFormat,
                S9sFormat      &valueFormat,
                int             depth);

        void printConfigBriefWiden(
                S9sVariantMap   map, 
                S9sFormat      &sectionFormat,
                S9sFormat      &nameFormat,
                S9sFormat      &valueFormat,
                int            depth); 

        void printConfigLong();


        void printClusterListBrief();
        void printClusterListLong();
        void printClusterListStat();
        
        void printHostTable(S9sCluster &cluster);
        void printClusterStat(S9sCluster &cluster);
        
        void printNodeListStat();
        void printNodeListBrief();
        void printNodeListLong();
        void printNodeStat(S9sCluster &cluster, S9sNode &node);

        
        void printJobListBrief();
        void printJobListLong();
        
        void printBackupListFormatString(const bool longFormat);

        void printBackupListDatabasesBrief();
        void printBackupListDatabasesLong();
        
        void printBackupListBrief();
        void printBackupListLong();

        void printBackupListFilesBrief();
        void printBackupListFilesLong();
        
        void printUserListBrief();
        void printUserListLong();
        
        void printAccountListBrief();
        void printAccountListLong();
        
        void printDatabaseListBrief();
        void printDatabaseListLong();
        
        void printGroupListBrief();
        void printGroupListLong();
        
        void printMaintenanceListBrief();
        void printMaintenanceListLong();

        void printMetaTypeListLong();
        void printMetaTypeListBrief();
        
        void printMetaTypePropertyListLong();
        void printMetaTypePropertyListBrief();

        const char *optNameColorBegin() const;
        const char *optNameColorEnd() const;

        const char *clusterColorBegin() const;
        const char *clusterColorEnd() const;
        
        const char *numberColorBegin() const;
        const char *numberColorEnd() const;
        
        const char *databaseColorBegin() const;
        const char *databaseColorEnd() const;

        const char *headerColorBegin() const;
        const char *headerColorEnd() const;
        
        const char *folderColorBegin() const;
        const char *folderColorEnd() const;

        const char *typeColorBegin() const;
        const char *typeColorEnd() const;
        
        const char *propertyColorBegin() const;
        const char *propertyColorEnd() const;
        
        const char *greyColorBegin() const;
        const char *greyColorEnd() const;

    private:
        void walkObjectTree(S9sVariantMap &node);

    private:
        S9sFormat   m_ownerFormat;
        S9sFormat   m_groupFormat;
        S9sFormat   m_sizeFormat;
        int         m_numberOfObjects;
        int         m_numberOfFolders;
};

