import com.michelin.cio.hudson.plugins.rolestrategy.*
import com.synopsys.arc.jenkins.plugins.rolestrategy.*    
import groovy.json.*
import groovy.json.JsonSlurper        
import hudson.*
import hudson.init.Initializer
import hudson.model.*
import hudson.security.*
import hudson.security.AuthorizationStrategy
import hudson.security.SecurityRealm
import java.lang.reflect.*
import java.util.*
import java.util.logging.*
import jenkins.model.*
import jenkins.model.Jenkins
import jenkins.plugins.git.GitSCMSource
import jenkins.plugins.git.traits.BranchDiscoveryTrait
import net.sf.json.JSONObject
import org.jenkinsci.plugins.GithubAuthorizationStrategy
import org.jenkinsci.plugins.GithubSecurityRealm
import org.jenkinsci.plugins.rolestrategy.permissions.PermissionHelper
import org.jenkinsci.plugins.workflow.libs.GlobalLibraries
import org.jenkinsci.plugins.workflow.libs.LibraryConfiguration
import org.jenkinsci.plugins.workflow.libs.SCMSourceRetriever

    
jenkins = Hudson.instance

if(!binding.hasVariable('github_realm')) {
    github_realm = [:]
}

Integer numberOfExecutors = 3
Jenkins.instance.setNumExecutors(numberOfExecutors)

if(!(github_realm instanceof Map)) {
    throw new Exception('github_realm must be a Map.')
}

git_hub_auth_id      = System.getenv().get("JENKINS_GITHUB_AUTH_ID")
git_hub_auth_secret  = System.getenv().get("JENKINS_GITHUB_AUTH_SECRET")            
gitToken             = System.getenv().get("GIT_TOKEN")
git_username         = System.getenv().get("GIT_USERNAME")

def env = System.getenv()
jsonSlurper = new JsonSlurper()


def googleDomainName    = jenkins.getRootUrl()

// Defining group
def members             = [:]
def adminMembers        = []
def contributorsMembers = []
def basicMembers        = []
def proMembers          = []
def premiumMembers      = []

// Defining global roles
def globalRoleAdmin        = "Admin"
def globalRoleContributors = "Contributors"
def globalRoleBasic        = "Basic"
def globalRolePro          = "Pro"
def globalRolePremium      = "Premium"


// Defining Permissions for each group
def adminPermissions = [
    "hudson.model.Hudson.Administer",
    "hudson.model.Hudson.Read"
]

def contributorsPermissions = [
    "hudson.model.Hudson.Read",
    "hudson.model.Item.Read",
    "hudson.model.Item.Discover",
    "hudson.model.Item.Build",
    "hudson.model.Item.Configure", 
    "hudson.model.Item.Create",
    "hudson.model.Item.Delete",
    "hudson.model.Item.Cancel",
    "hudson.model.Run.Replay",
    "hudson.model.View.Create",
    "hudson.model.View.Configure",
    "hudson.model.View.Delete",
    "hudson.model.View.Read"
]

def basicPermissions = [
    "hudson.model.Hudson.Read",
    "hudson.model.Item.Read",
    "hudson.model.Item.Discover",
    "hudson.model.Item.Build"
]

def proPermissions = [
    "hudson.model.Hudson.Read",
    "hudson.model.Item.Read",
    "hudson.model.Item.Discover",
    "hudson.model.Item.Build"
]

def premiumPermissions = [
    "hudson.model.Hudson.Read",
    "hudson.model.Item.Read",
    "hudson.model.Item.Discover",
    "hudson.model.Item.Build"
]

/**
Function to compare if the two global shared libraries are equal.
*/
boolean isLibrariesEqual(List lib1, List lib2) {
    lib1.size() == lib2.size() &&
    !(
        false in [lib1, lib2].transpose().collect { l1, l2 ->
            def s1 = l1.retriever.scm
            def s2 = l2.retriever.scm
            l1.retriever.class == l2.retriever.class &&
            l1.name == l2.name &&
            l1.defaultVersion == l2.defaultVersion &&
            l1.implicit == l2.implicit &&
            l1.allowVersionOverride == l2.allowVersionOverride &&
            l1.includeInChangesets == l2.includeInChangesets &&
            s1.remote == s2.remote &&
            s1.credentialsId == s2.credentialsId &&
            s1.traits.size() == s2.traits.size() &&
            !(
                false in [s1.traits, s2.traits].transpose().collect { t1, t2 ->
                    t1.class == t2.class
                }
            )
        }
    )
}

def getTeamId(teamName) {
    /*
        Function to find teams ID
    */
    def organization = "fuchicorp"
    def teamsUrl = "https://api.github.com/orgs/" + organization + "/teams"
    def teamId = null
    def get = new URL(teamsUrl).openConnection();
        get.setRequestMethod("GET")
        get.setRequestProperty("Authorization", "token " + gitToken)
        get.setRequestProperty("Content-Type", "application/json")

    def data = jsonSlurper.parseText(get.getInputStream().getText())
    data.each() {
        if (it.name.toLowerCase() == teamName.toLowerCase()) {
        teamId = it.id
        }
    }
    return teamId
}

def getTeamMembers(teamName) {
    /*
    Function to find team members from github
    */
    def getTeamId = getTeamId(teamName)
    def totalUsers = []
    def memberUrl = ""
    def pageCount = 1
    while (true) {
        // While loop to go each pages and get all members from team 
        memberUrl = "https://api.github.com/teams/" + getTeamId + "/members?page=" + pageCount
        def get = new URL(memberUrl).openConnection();
        get.setRequestMethod("GET")
        get.setRequestProperty("Authorization", "token "+ gitToken)
        get.setRequestProperty("Content-Type", "application/json")
        def object = jsonSlurper.parseText(get.getInputStream().getText())

        //  Braking the while loop when no one found in the page
        if (! object.login) {
            break;
        }

        // Adding list of found people to totalUsers
        object.login.each{ totalUsers.add(it) }
        pageCount = pageCount + 1
    }
    return totalUsers
}

pipeline_shared_libraries = [
    'CommonLib': [
        'defaultVersion': 'master',
        'implicit': true,
        'allowVersionOverride': true,
        'includeInChangesets': false,
        'scm': [
            'remote': 'https://github.com/fuchicorp/jenkins-global-library.git',
            'credentialsId': 'github-common-access'
        ]
    ]
]

if(!binding.hasVariable('pipeline_shared_libraries')) {
    pipeline_shared_libraries = [:]
}

if(!pipeline_shared_libraries in Map) {
    throw new Exception("pipeline_shared_libraries must be an instance of Map but instead is instance of: "+ pipeline_shared_libraries.getClass())
}

pipeline_shared_libraries = pipeline_shared_libraries as JSONObject
List libraries = [] as ArrayList
pipeline_shared_libraries.each { name, config ->
    if(name && config && config in Map && 'scm' in config && config['scm'] in Map && 'remote' in config['scm'] && config['scm'].optString('remote')) {
        def scm = new GitSCMSource(config['scm'].optString('remote'))
        scm.credentialsId = config['scm'].optString('credentialsId')
        scm.traits = [new BranchDiscoveryTrait()]
        def retriever = new SCMSourceRetriever(scm)
        def library = new LibraryConfiguration(name, retriever)
        library.defaultVersion = config.optString('defaultVersion')
        library.implicit = config.optBoolean('implicit', false)
        library.allowVersionOverride = config.optBoolean('allowVersionOverride', true)
        library.includeInChangesets = config.optBoolean('includeInChangesets', true)
        libraries << library
    }
}

def global_settings = Jenkins.instance.getExtensionList(GlobalLibraries.class)[0]
if(libraries && !isLibrariesEqual(global_settings.libraries, libraries)) {
    global_settings.libraries = libraries
    global_settings.save()
    println 'Configured Pipeline Global Shared Libraries:\n    ' + global_settings.libraries.collect { it.name }.join('\n    ')
} else {
    if(pipeline_shared_libraries) {
        println 'Nothing changed.  Pipeline Global Shared Libraries already configured.'
    } else {
        println 'Nothing changed.  Skipped configuring Pipeline Global Shared Libraries because settings are empty.'
    }
}

github_realm = github_realm as JSONObject
String githubWebUri = github_realm.optString('web_uri', GithubSecurityRealm.DEFAULT_WEB_URI)
String githubApiUri = github_realm.optString('api_uri', GithubSecurityRealm.DEFAULT_API_URI)
String oauthScopes = github_realm.optString('oauth_scopes', GithubSecurityRealm.DEFAULT_OAUTH_SCOPES)
String clientID = github_realm.optString('client_id', git_hub_auth_id)
String clientSecret = github_realm.optString('client_secret', git_hub_auth_secret)

if(!Jenkins.instance.isQuietingDown()) {
    if(clientID && clientSecret) {
        SecurityRealm github_realm = new GithubSecurityRealm(githubWebUri, githubApiUri, clientID, clientSecret, oauthScopes)
        if(!github_realm.equals(Jenkins.instance.getSecurityRealm())) {
            Jenkins.instance.setSecurityRealm(github_realm)
            println 'Security realm configuration has changed.  Configured GitHub security realm.'
        } else {
            println 'Nothing changed.  GitHub security realm already configured.'
        }
    }
} else {
    println 'Shutdown mode enabled.  Configure GitHub security realm SKIPPED.'
}


// Getting all teams and members of the teams from GitHub
try {
    members['admin']        = getTeamMembers("admin")
} catch (e) { println("detected an error with getting admin team and its members" + e) }

try {
    members['basic']        = getTeamMembers("basic")
} catch (e) { println("detected an error with getting basic team and its members" + e) }

try {
    members['contributors'] = getTeamMembers("contributors")
} catch (e) { println("detected an error with getting contributors team and its members" + e) }

try {
    members['pro']          = getTeamMembers("pro")
} catch (e) { println("detected an error with getting pro team and its members" + e) }

try {
    members['premium']      = getTeamMembers("premium")
} catch (e) { println("detected an error with getting premium team and its members" + e) }



// Adding members to different groups based on their GitHub teams
try {
    adminMembers.addAll(members['admin'])
    adminMembers.add(git_username)
} catch (e) { println("detected error" + e) }
try {
    contributorsMembers.addAll(members['contributors'])
} catch (e) { println("detected error" + e) }
try {
    basicMembers.addAll(members['basic'])
} catch (e) { println("detected error" + e) }
try {
    proMembers.addAll(members['pro'])
} catch (e) { println("detected error" + e) }
try {
    premiumMembers.addAll(members['premium'])
} catch (e) { println("detected error" + e) }



if (env.AUTHZ_JSON_FILE)  {
    println "Get role authorizations from file " + env.AUTHZ_JSON_FILE
    File f = new File(env.AUTHZ_JSON_FILE)
    def jsonSlurper = new JsonSlurper()
    def jsonText = f.getText()
    access = jsonSlurper.parseText( jsonText )
} else if (env.AUTH_JSON_URL) {
    println "Get role authorizations from URL " + env.AUTHZ_JSON_URL
    URL jsonUrl = new URL(env.AUTHZ_JSON_URL);
    access = new JsonSlurper().parse(jsonUrl);
} else {
    println "Warning! Neither env.AUTHZ_JSON_FILE nor env.AUTHZ_JSON_URL specified!"
    println "Granting anonymous admin access"
}


/**
* ===================================
*
*           Permissions
*
* ===================================
*/
// TODO: drive these from a config file

def roleBasedAuthenticationStrategy = new RoleBasedAuthorizationStrategy()
Jenkins.instance.setAuthorizationStrategy(roleBasedAuthenticationStrategy)
Constructor[] constrs = Role.class.getConstructors();
for (Constructor<?> c : constrs) {
    c.setAccessible(true);
}

// Make the method assignRole accessible
Method assignRoleMethod = RoleBasedAuthorizationStrategy.class.getDeclaredMethod("assignRole", RoleType.class, Role.class, String.class);
assignRoleMethod.setAccessible(true);
println("HACK! changing visibility of RoleBasedAuthorizationStrategy.assignRole")


// Synching permissions based on Permissions for each group to be Set to their groups
Set<Permission> adminPermissionSet = new HashSet<Permission>();
adminPermissions.each { p ->
    def permission = Permission.fromId(p);
    if (permission != null) {
        adminPermissionSet.add(permission);
    } else {
        println(p + " is not a valid permission ID (ignoring)")
    }
}

Set<Permission> contributorsPermissionSet = new HashSet<Permission>();
contributorsPermissions.each { p ->
    def permission = Permission.fromId(p);
    if (permission != null) {
        contributorsPermissionSet.add(permission);
    } else {
        println(p + " is not a valid permission ID (ignoring)")
    }
}

Set<Permission> basicPermissionSet = new HashSet<Permission>();
basicPermissions.each { p ->
    def permission = Permission.fromId(p);
    if (permission != null) {
        basicPermissionSet.add(permission);
    } else {
        println(p + " is not a valid permission ID (ignoring)")
    }
}

Set<Permission> proPermissionSet = new HashSet<Permission>();
proPermissions.each { p ->
    def permission = Permission.fromId(p);
    if (permission != null) {
        proPermissionSet.add(permission);
    } else {
        println(p + " is not a valid permission ID (ignoring)")
    }
}

Set<Permission> premiumPermissionSet = new HashSet<Permission>();
premiumPermissions.each { p ->
    def permission = Permission.fromId(p);
    if (permission != null) {
        premiumPermissionSet.add(permission);
    } else {
        println(p + " is not a valid permission ID (ignoring)")
    }
}

// Assigned permissions to the different groups using roleBasedAuthenticationStrategy
// admins
Role adminRole = new Role(globalRoleAdmin, adminPermissionSet);
roleBasedAuthenticationStrategy.addRole(RoleType.Global, adminRole);

// contributors
Role contributorsRole = new Role(globalRoleContributors, contributorsPermissionSet);
roleBasedAuthenticationStrategy.addRole(RoleType.Global, contributorsRole);

// basic
Role basicRole = new Role(globalRoleBasic, basicPermissionSet);
roleBasedAuthenticationStrategy.addRole(RoleType.Global, basicRole);

// pro
Role proRole = new Role(globalRolePro, proPermissionSet);
roleBasedAuthenticationStrategy.addRole(RoleType.Global, proRole);

// premium
Role premiumRole = new Role(globalRolePremium, premiumPermissionSet);
roleBasedAuthenticationStrategy.addRole(RoleType.Global, premiumRole);


// Giving access to each member based on their roles and permissions
def access = [
    admins: adminMembers,
    contributors: contributorsMembers,
    basics: basicMembers,
    pros: proMembers,
    premiums: premiumMembers
]

access.admins.each { l ->
    println("Granting adminPermissions to " + l)
    roleBasedAuthenticationStrategy.assignRole(RoleType.Global, adminRole, l);
}
access.contributors.each { l ->
    println("Granting contributorsPermissions to " + l)
    roleBasedAuthenticationStrategy.assignRole(RoleType.Global, contributorsRole, l);
}
access.basics.each { l ->
    println("Granting basicPermissions to " + l)
    roleBasedAuthenticationStrategy.assignRole(RoleType.Global, basicRole, l);
}
access.pros.each { l ->
    println("Granting proPermissions to " + l)
    roleBasedAuthenticationStrategy.assignRole(RoleType.Global, proRole, l);
}
access.premiums.each { l ->
    println("Granting premiumPermissions to " + l)
    roleBasedAuthenticationStrategy.assignRole(RoleType.Global, premiumRole, l);
}

Jenkins.instance.save()  

println('##### The init script is finished! #####')